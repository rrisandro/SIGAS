-- ============================================================================
-- SIGAS · Códigos únicos de 3 caracteres + validación de datos
-- Fecha: 2026-10-30
--
-- Incluye:
--   1. Columnas codigo en familias y jefe_de_calle.
--   2. Generación automática de códigos alfanuméricos únicos de 3 caracteres.
--   3. Backfill de los registros existentes (no borra ni modifica otros datos).
--   4. Retorno del código en registrar_familia_pendiente.
--   5. Validaciones de longitud y tipo en las RPC de registro/edición.
--
-- Ejecutar en Supabase → SQL Editor. Es idempotente.
-- ============================================================================

begin;

-- ============================================================================
-- 1. COLUMNAS codigo
-- ============================================================================
alter table public.familias add column if not exists codigo text;
alter table public.jefe_de_calle add column if not exists codigo text;

-- ============================================================================
-- 2. GENERADOR DE CÓDIGOS
--    - 3 caracteres: letras A-Z y números 0-9.
--    - Se excluyen I, O, 0 y 1 para evitar confusiones al dictarlos.
--    - Un lock de transacción serializa la comprobación entre ambas tablas,
--      garantizando que un código no se repita en familias ni en jefes.
-- ============================================================================
create or replace function public.sigas_asignar_codigo()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_alfabeto constant text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  v_codigo text;
  v_intento integer;
  v_posicion integer;
begin
  -- Si el código viene informado, se normaliza y se valida.
  if new.codigo is not null and btrim(new.codigo) <> '' then
    new.codigo := upper(btrim(new.codigo));

    if new.codigo !~ '^[A-Z0-9]{3}$' then
      raise exception 'El código debe tener exactamente 3 caracteres alfanuméricos.'
        using errcode = '22023';
    end if;

    perform pg_advisory_xact_lock(hashtext('sigas_codigo_unico'));

    if (tg_table_name = 'familias'
        and exists (select 1 from public.jefe_de_calle j where j.codigo = new.codigo))
       or (tg_table_name = 'jefe_de_calle'
        and exists (select 1 from public.familias f where f.codigo = new.codigo)) then
      raise exception 'El código % ya está en uso.', new.codigo using errcode = '23505';
    end if;

    return new;
  end if;

  perform pg_advisory_xact_lock(hashtext('sigas_codigo_unico'));

  for v_intento in 1..100 loop
    v_codigo := '';

    for v_posicion in 1..3 loop
      v_codigo := v_codigo || substr(
        v_alfabeto,
        1 + floor(random() * length(v_alfabeto))::integer,
        1
      );
    end loop;

    if not exists (select 1 from public.familias f where f.codigo = v_codigo)
       and not exists (select 1 from public.jefe_de_calle j where j.codigo = v_codigo) then
      new.codigo := v_codigo;
      return new;
    end if;
  end loop;

  raise exception 'No fue posible generar un código único. Intenta nuevamente.'
    using errcode = '23505';
end;
$$;

drop trigger if exists trg_familias_codigo on public.familias;
create trigger trg_familias_codigo
before insert or update of codigo on public.familias
for each row execute function public.sigas_asignar_codigo();

drop trigger if exists trg_jefe_de_calle_codigo on public.jefe_de_calle;
create trigger trg_jefe_de_calle_codigo
before insert or update of codigo on public.jefe_de_calle
for each row execute function public.sigas_asignar_codigo();

-- ============================================================================
-- 3. BACKFILL DE REGISTROS EXISTENTES
--    Al poner codigo = null el trigger genera uno nuevo. No se toca ningún
--    otro dato de las familias ni de los jefes de calle.
-- ============================================================================
update public.familias
set codigo = null
where codigo is null or codigo !~ '^[A-Z0-9]{3}$';

update public.jefe_de_calle
set codigo = null
where codigo is null or codigo !~ '^[A-Z0-9]{3}$';

-- ============================================================================
-- 4. RESTRICCIONES E ÍNDICES ÚNICOS
-- ============================================================================
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'familias_codigo_check'
      and conrelid = 'public.familias'::regclass
  ) then
    alter table public.familias
      add constraint familias_codigo_check
      check (codigo is null or codigo ~ '^[A-Z0-9]{3}$');
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'jefe_de_calle_codigo_check'
      and conrelid = 'public.jefe_de_calle'::regclass
  ) then
    alter table public.jefe_de_calle
      add constraint jefe_de_calle_codigo_check
      check (codigo is null or codigo ~ '^[A-Z0-9]{3}$');
  end if;
end $$;

create unique index if not exists uq_familias_codigo
  on public.familias (codigo)
  where codigo is not null;

create unique index if not exists uq_jefe_de_calle_codigo
  on public.jefe_de_calle (codigo)
  where codigo is not null;

-- ============================================================================
-- 5. RPC · REGISTRO PÚBLICO DE FAMILIA
--    Devuelve el código generado y valida tipo/longitud de los datos.
-- ============================================================================
create or replace function public.registrar_familia_pendiente(
  p_id integer,
  p_auth_id uuid,
  p_nombre text,
  p_id_calle integer,
  p_telefono text default null,
  p_direccion text default null,
  p_personas integer default null,
  p_email text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_jefe public.jefe_de_calle%rowtype;
  v_notificado boolean := false;
  v_codigo text;
  v_nombre text;
  v_telefono text;
  v_direccion text;
  v_email text;
begin
  if p_auth_id is null then
    raise exception 'La cuenta de acceso es obligatoria.' using errcode = '22023';
  end if;

  v_nombre := nullif(trim(p_nombre), '');
  if v_nombre is null then
    raise exception 'El nombre de la familia es obligatorio.' using errcode = '22023';
  end if;
  if length(v_nombre) < 2 or length(v_nombre) > 120 then
    raise exception 'El nombre de la familia debe tener entre 2 y 120 caracteres.'
      using errcode = '22023';
  end if;
  if v_nombre ~ '[0-9]' then
    raise exception 'El nombre de la familia solo puede contener letras y espacios.'
      using errcode = '22023';
  end if;

  if p_id is null or p_id <= 0 or p_id > 2147483647 then
    raise exception 'La cédula no es válida.' using errcode = '22023';
  end if;

  v_telefono := nullif(trim(p_telefono), '');
  if v_telefono is not null then
    if v_telefono !~ '^[0-9]{7,12}$' then
      raise exception 'El teléfono debe tener entre 7 y 12 dígitos.' using errcode = '22023';
    end if;
  end if;

  v_direccion := nullif(trim(p_direccion), '');
  if v_direccion is not null and length(v_direccion) > 200 then
    raise exception 'La dirección no puede superar los 200 caracteres.' using errcode = '22023';
  end if;

  if p_personas is not null and (p_personas < 1 or p_personas > 30) then
    raise exception 'El número de personas debe estar entre 1 y 30.' using errcode = '22023';
  end if;

  v_email := nullif(trim(p_email), '');
  if v_email is not null then
    if length(v_email) > 254 or v_email !~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]{2,}$' then
      raise exception 'El correo electrónico no tiene un formato válido.' using errcode = '22023';
    end if;
  end if;

  if p_id_calle is null or not exists (
    select 1 from public.calles c
    where c.id_calle = p_id_calle and c.is_deleted = false
  ) then
    raise exception 'La calle seleccionada no existe o fue dada de baja.' using errcode = '22023';
  end if;

  if exists (select 1 from public.familias f where f.id = p_id) then
    raise exception 'Ya existe un registro con esa cédula. Contacta al Jefe de Calle.'
      using errcode = '23505';
  end if;

  if exists (
    select 1 from public.familias f
    where f.auth_id = p_auth_id
      and f.is_deleted = false
  ) then
    raise exception 'Esta cuenta ya tiene un registro de familia asociado.'
      using errcode = '22023';
  end if;

  insert into public.familias (
    id,
    auth_id,
    nombre_familia,
    id_calle,
    id_cargo,
    activo,
    estado,
    telefono,
    direccion,
    num_personas,
    email,
    is_deleted
  )
  values (
    p_id,
    p_auth_id,
    v_nombre,
    p_id_calle,
    3,
    false,
    'pendiente',
    v_telefono,
    v_direccion,
    p_personas,
    v_email,
    false
  )
  returning codigo into v_codigo;

  select j.* into v_jefe
  from public.jefe_de_calle j
  where j.id_calle = p_id_calle
    and j.activo = true
    and j.is_deleted = false
  order by j.id_jefe_calle
  limit 1;

  if v_jefe.id_jefe_calle is null then
    select j.* into v_jefe
    from public.calles c
    join public.jefe_de_calle j on j.id_jefe_calle = c.id_jefe_calle
    where c.id_calle = p_id_calle
      and j.activo = true
      and j.is_deleted = false
    order by j.id_jefe_calle
    limit 1;
  end if;

  if v_jefe.id_jefe_calle is not null and v_jefe.auth_id is not null then
    perform public.sigas_notificar(
      v_jefe.auth_id,
      v_jefe.id_jefe_calle,
      p_id,
      'registro_familia',
      'Nuevo registro pendiente',
      format(
        'La familia %s (cédula %s, código %s) solicitó registro en tu calle.',
        v_nombre,
        p_id,
        v_codigo
      ),
      jsonb_build_object(
        'id_familia', p_id,
        'id_calle', p_id_calle,
        'email', v_email,
        'codigo', v_codigo
      )
    );
    v_notificado := true;
  end if;

  return jsonb_build_object(
    'ok', true,
    'id_familia', p_id,
    'codigo', v_codigo,
    'notificado', v_notificado
  );
exception
  when unique_violation then
    raise exception 'Ya existe un registro con esa cédula. Contacta al Jefe de Calle.'
      using errcode = '23505';
end;
$$;

-- ============================================================================
-- 6. RPC · ACTUALIZAR REGISTRO DE FAMILIA
--    Mismas validaciones que el formulario del Jefe de Calle.
-- ============================================================================
create or replace function public.actualizar_registro_familia(
  p_id_familia integer,
  p_nombre text,
  p_telefono text default null,
  p_direccion text default null,
  p_personas integer default null,
  p_id_calle integer default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_familia public.familias%rowtype;
  v_nombre text;
  v_telefono text;
  v_direccion text;
begin
  if not public.sigas_puede_gestionar_familia(p_id_familia) then
    raise exception 'No tienes permiso para modificar este registro.' using errcode = '42501';
  end if;

  v_nombre := nullif(trim(p_nombre), '');
  if v_nombre is null then
    raise exception 'El nombre es obligatorio.' using errcode = '22023';
  end if;
  if length(v_nombre) < 2 or length(v_nombre) > 120 then
    raise exception 'El nombre debe tener entre 2 y 120 caracteres.' using errcode = '22023';
  end if;
  if v_nombre ~ '[0-9]' then
    raise exception 'El nombre solo puede contener letras y espacios.' using errcode = '22023';
  end if;

  v_telefono := nullif(trim(p_telefono), '');
  if v_telefono is not null and v_telefono !~ '^[0-9]{7,12}$' then
    raise exception 'El teléfono debe tener entre 7 y 12 dígitos.' using errcode = '22023';
  end if;

  v_direccion := nullif(trim(p_direccion), '');
  if v_direccion is not null and length(v_direccion) > 200 then
    raise exception 'La dirección no puede superar los 200 caracteres.' using errcode = '22023';
  end if;

  if p_personas is not null and (p_personas < 1 or p_personas > 30) then
    raise exception 'El número de personas debe estar entre 1 y 30.' using errcode = '22023';
  end if;

  select * into v_familia
  from public.familias
  where id = p_id_familia and is_deleted = false
  for update;

  if not found then
    raise exception 'El registro ya no existe o fue eliminado.' using errcode = 'P0002';
  end if;

  if p_id_calle is not null
     and p_id_calle is distinct from v_familia.id_calle
     and not public.sigas_es_admin() then
    raise exception 'Solo un administrador puede cambiar la calle de una familia.'
      using errcode = '42501';
  end if;

  if p_id_calle is not null and not exists (
    select 1 from public.calles c
    where c.id_calle = p_id_calle and c.is_deleted = false
  ) then
    raise exception 'La calle seleccionada no existe o fue dada de baja.' using errcode = '22023';
  end if;

  update public.familias
  set nombre_familia = v_nombre,
      telefono = v_telefono,
      direccion = v_direccion,
      num_personas = p_personas,
      id_calle = coalesce(p_id_calle, id_calle),
      updated_at = now()
  where id = p_id_familia;

  update public.jefes_familia
  set nombre = v_nombre,
      telefono = v_telefono,
      id_calle = coalesce(p_id_calle, id_calle),
      updated_at = now()
  where id_familia = p_id_familia
    and activo = true
    and is_deleted = false;

  return jsonb_build_object(
    'ok', true,
    'id_familia', p_id_familia,
    'codigo', v_familia.codigo
  );
end;
$$;

commit;
