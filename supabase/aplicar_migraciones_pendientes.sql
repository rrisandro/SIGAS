-- ============================================================================
-- SIGAS · Migraciones pendientes para Supabase
-- ----------------------------------------------------------------------------
-- Pegar este archivo completo en Supabase → SQL Editor y ejecutarlo.
-- Orden: códigos/validación → Jefes de Familia → administración de Jefes
--        → Jefes de Calle (autorregistro y multicalle) → fix cambio de rol.
--
-- Las cinco migraciones son idempotentes y NO borran datos existentes.
-- ============================================================================

-- ############################################################################
-- 1/5 · 20261030_codigos_y_validacion.sql
-- ############################################################################

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


-- ############################################################################
-- 2/5 · 20261107_jefes_familia_cuenta_unica.sql
-- ############################################################################

-- ============================================================================
-- SIGAS · Jefes de Familia con cuenta única
-- ----------------------------------------------------------------------------
-- Objetivo:
--   1. Un Jefe de Familia activo por familia (ya existía).
--   2. Una cuenta de acceso (auth_id) no puede estar vinculada a dos familias.
--   3. Una cédula no puede estar vinculada a dos Jefes de Familia activos.
--   4. El Jefe de Calle puede registrar al Jefe de Familia de una familia que
--      ya estaba censada, aunque todavía no tenga cuenta de acceso.
--   5. Cuando la persona se registra desde el login con la cédula de una
--      familia ya censada, su cuenta se vincula a esa familia y queda
--      pendiente de aprobación por el Jefe de Calle.
--
-- Esta migración NO borra datos. Solo normaliza cédulas, agrega índices,
-- reemplaza funciones y crea una función nueva.
-- ============================================================================

begin;

-- ----------------------------------------------------------------------------
-- 0. Verificar que exista la tabla base de Jefes de Familia.
-- ----------------------------------------------------------------------------
do $$
begin
  if to_regclass('public.jefes_familia') is null then
    raise exception 'Falta la migración 20261028_sigas_mejoras.sql: no existe public.jefes_familia.';
  end if;
end $$;

-- ----------------------------------------------------------------------------
-- 1. Normalizar cédulas existentes (solo dígitos).
-- ----------------------------------------------------------------------------
update public.jefes_familia
set ci = nullif(regexp_replace(ci, '\D', '', 'g'), '')
where ci is not null
  and ci is distinct from nullif(regexp_replace(ci, '\D', '', 'g'), '');

-- ----------------------------------------------------------------------------
-- 2. Diagnóstico previo: si hay duplicados, la migración se detiene con un
--    mensaje claro en lugar de crear índices sobre datos inconsistentes.
-- ----------------------------------------------------------------------------
do $$
declare
  v_dup record;
begin
  for v_dup in
    select auth_id, count(*) as total
    from public.familias
    where auth_id is not null
      and is_deleted = false
    group by auth_id
    having count(*) > 1
  loop
    raise exception
      'La cuenta % está vinculada a % familias activas. Corrige ese duplicado antes de aplicar esta migración.',
      v_dup.auth_id, v_dup.total;
  end loop;

  for v_dup in
    select auth_id, count(*) as total
    from public.jefes_familia
    where auth_id is not null
      and activo = true
      and is_deleted = false
    group by auth_id
    having count(*) > 1
  loop
    raise exception
      'La cuenta % está vinculada a % Jefes de Familia activos. Corrige ese duplicado antes de aplicar esta migración.',
      v_dup.auth_id, v_dup.total;
  end loop;

  for v_dup in
    select regexp_replace(ci, '\D', '', 'g') as cedula, count(*) as total
    from public.jefes_familia
    where ci is not null
      and activo = true
      and is_deleted = false
      and regexp_replace(ci, '\D', '', 'g') <> ''
    group by regexp_replace(ci, '\D', '', 'g')
    having count(*) > 1
  loop
    raise exception
      'La cédula % está vinculada a % Jefes de Familia activos. Corrige ese duplicado antes de aplicar esta migración.',
      v_dup.cedula, v_dup.total;
  end loop;
end $$;

-- ----------------------------------------------------------------------------
-- 3. Índices únicos.
--    - familias.auth_id: una cuenta = una familia vigente.
--    - jefes_familia.auth_id: una cuenta = un Jefe de Familia activo.
--    - jefes_familia.ci: una cédula = un Jefe de Familia activo.
--    El índice uq_jefes_familia_activo (una familia = un jefe activo) ya
--    existe desde la migración 20261028.
-- ----------------------------------------------------------------------------
create unique index if not exists uq_familias_auth_activo
  on public.familias (auth_id)
  where auth_id is not null
    and is_deleted = false;

create unique index if not exists uq_jefes_familia_auth_activo
  on public.jefes_familia (auth_id)
  where auth_id is not null
    and activo = true
    and is_deleted = false;

create unique index if not exists uq_jefes_familia_ci_activo
  on public.jefes_familia ((regexp_replace(ci, '\D', '', 'g')))
  where ci is not null
    and activo = true
    and is_deleted = false
    and regexp_replace(ci, '\D', '', 'g') <> '';

-- ----------------------------------------------------------------------------
-- 4. Normalización automática de cédula y teléfono del Jefe de Familia.
-- ----------------------------------------------------------------------------
create or replace function public.sigas_normalizar_jefe_familia()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  new.nombre := btrim(new.nombre);

  if new.ci is not null then
    new.ci := nullif(regexp_replace(new.ci, '\D', '', 'g'), '');
  end if;

  if new.telefono is not null then
    new.telefono := nullif(regexp_replace(new.telefono, '\D', '', 'g'), '');
  end if;

  return new;
end;
$$;

drop trigger if exists trg_jefes_familia_normalizar on public.jefes_familia;
create trigger trg_jefes_familia_normalizar
before insert or update on public.jefes_familia
for each row execute function public.sigas_normalizar_jefe_familia();

revoke all on function public.sigas_normalizar_jefe_familia() from public;

-- ----------------------------------------------------------------------------
-- 4.1 Permitir la vinculación de cuenta desde el registro público.
--     El trigger original bloquea cualquier cambio de auth_id hecho por un
--     usuario que no sea administrador. La vinculación necesita exactamente
--     ese cambio, pero solo cuando:
--       - la familia todavía no tenía cuenta (old.auth_id is null),
--       - la cuenta nueva es la que se está vinculando (GUC interna de la RPC)
--         o la de la sesión actual,
--       - no se tocan los demás campos sensibles.
--     La RPC marca la transacción con sigas.vinculando_cuenta antes de
--     actualizar; así una actualización directa a la tabla sigue bloqueada.
-- ----------------------------------------------------------------------------
create or replace function public.sigas_proteger_campos_familia()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_vinculacion_propia boolean;
begin
  if public.sigas_es_admin() then
    return new;
  end if;

  v_vinculacion_propia :=
    old.auth_id is null
    and new.auth_id is not null
    and (
      new.auth_id = auth.uid()
      or current_setting('sigas.vinculando_cuenta', true) = new.auth_id::text
    );

  if new.id is distinct from old.id
     or (new.auth_id is distinct from old.auth_id and not v_vinculacion_propia)
     or new.id_cargo is distinct from old.id_cargo
     or (
       new.id_calle is distinct from old.id_calle
       and not (v_vinculacion_propia and old.id_calle is null)
     )
     or new.is_deleted is distinct from old.is_deleted
     or new.deleted_at is distinct from old.deleted_at
  then
    raise exception 'No tienes permiso para modificar esos campos del registro.'
      using errcode = '42501';
  end if;

  if new.estado = 'aprobado'
     and old.estado is distinct from 'aprobado'
     and not exists (
       select 1 from public.jefes_familia jf
       where jf.id_familia = new.id
         and jf.activo = true
         and jf.is_deleted = false
     )
  then
    raise exception 'Debes registrar un Jefe de Familia activo antes de aprobar el registro.'
      using errcode = '23514';
  end if;

  return new;
end;
$$;

revoke all on function public.sigas_proteger_campos_familia() from public;

-- ----------------------------------------------------------------------------
-- 5. RPC · Registrar al Jefe de Familia de una familia ya censada.
--    Lo usa el Jefe de Calle desde su panel. El registro queda pendiente
--    hasta que la persona cree su cuenta y el Jefe de Calle la apruebe.
-- ----------------------------------------------------------------------------
create or replace function public.registrar_jefe_familia(
  p_id_familia integer,
  p_nombre text,
  p_telefono text default null,
  p_email text default null,
  p_auth_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_familia public.familias%rowtype;
  v_jefe public.jefes_familia%rowtype;
  v_nombre text;
  v_telefono text;
  v_email text;
begin
  if not public.sigas_puede_gestionar_familia(p_id_familia) then
    raise exception 'No tienes permiso para registrar al Jefe de Familia de esta familia.'
      using errcode = '42501';
  end if;

  -- El Jefe de Calle registra datos y deja el registro pendiente; la cuenta
  -- la crea la propia persona desde el login. Solo un administrador puede
  -- vincular una cuenta ya existente desde este RPC.
  if p_auth_id is not null and not public.sigas_es_admin() then
    raise exception 'Solo un administrador puede vincular una cuenta de acceso existente.'
      using errcode = '42501';
  end if;

  select * into v_familia
  from public.familias
  where id = p_id_familia
    and is_deleted = false
  for update;

  if not found then
    raise exception 'La familia no existe o fue dada de baja.' using errcode = 'P0002';
  end if;

  if v_familia.id_calle is null then
    raise exception 'La familia no tiene una calle asignada.' using errcode = '23514';
  end if;

  v_nombre := nullif(btrim(p_nombre), '');
  if v_nombre is null then
    raise exception 'El nombre del Jefe de Familia es obligatorio.' using errcode = '22023';
  end if;

  v_telefono := nullif(regexp_replace(coalesce(p_telefono, ''), '\D', '', 'g'), '');
  v_email := nullif(lower(btrim(coalesce(p_email, ''))), '');

  if v_email is not null
     and v_email !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]{2,}$' then
    raise exception 'El correo del Jefe de Familia no es válido.' using errcode = '22023';
  end if;

  select * into v_jefe
  from public.jefes_familia
  where id_familia = p_id_familia
    and is_deleted = false
  order by activo desc, created_at desc
  limit 1
  for update;

  if found and v_jefe.activo then
    raise exception
      'La familia ya tiene un Jefe de Familia activo (%). Debes darlo de baja antes de asignar otro.',
      coalesce(v_jefe.nombre, 'ID ' || v_jefe.id_jefe_familia)
      using errcode = 'P0001';
  end if;

  if p_auth_id is not null then
    if v_familia.auth_id is not null and v_familia.auth_id is distinct from p_auth_id then
      raise exception 'La familia ya tiene una cuenta de acceso vinculada.' using errcode = 'P0001';
    end if;

    if exists (
      select 1
      from public.familias f
      where f.auth_id = p_auth_id
        and f.id <> p_id_familia
        and f.is_deleted = false
    ) then
      raise exception 'Esta cuenta ya está vinculada a otra familia.' using errcode = 'P0001';
    end if;

    if exists (
      select 1
      from public.jefes_familia j
      where j.auth_id = p_auth_id
        and j.id_familia <> p_id_familia
        and j.activo = true
        and j.is_deleted = false
    ) then
      raise exception 'Esta cuenta ya es Jefe de Familia de otra familia.' using errcode = 'P0001';
    end if;
  end if;

  if found then
    update public.jefes_familia
    set nombre = v_nombre,
        ci = p_id_familia::text,
        telefono = v_telefono,
        auth_id = coalesce(p_auth_id, auth_id),
        estado = case when p_auth_id is not null then 'aprobado' else 'pendiente' end,
        activo = (p_auth_id is not null),
        id_calle = v_familia.id_calle,
        updated_at = now()
    where id_jefe_familia = v_jefe.id_jefe_familia
    returning * into v_jefe;
  else
    insert into public.jefes_familia (
      id_familia,
      auth_id,
      id_calle,
      nombre,
      ci,
      telefono,
      activo,
      estado,
      is_deleted
    )
    values (
      p_id_familia,
      p_auth_id,
      v_familia.id_calle,
      v_nombre,
      p_id_familia::text,
      v_telefono,
      (p_auth_id is not null),
      case when p_auth_id is not null then 'aprobado' else 'pendiente' end,
      false
    )
    returning * into v_jefe;
  end if;

  if p_auth_id is not null then
    update public.familias
    set auth_id = p_auth_id,
        email = coalesce(email, v_email),
        updated_at = now()
    where id = p_id_familia;
  elsif v_email is not null then
    update public.familias
    set email = v_email,
        updated_at = now()
    where id = p_id_familia
      and auth_id is null;
  end if;

  return jsonb_build_object(
    'ok', true,
    'id_familia', p_id_familia,
    'id_jefe_familia', v_jefe.id_jefe_familia,
    'estado', v_jefe.estado,
    'activo', v_jefe.activo,
    'tiene_cuenta', v_jefe.auth_id is not null
  );
end;
$$;

revoke all on function public.registrar_jefe_familia(integer, text, text, text, uuid) from public;
grant execute on function public.registrar_jefe_familia(integer, text, text, text, uuid) to authenticated;

-- ----------------------------------------------------------------------------
-- 6. RPC · Consultar disponibilidad de una cédula antes de crear la cuenta.
--    Evita crear cuentas de Authentication que luego no se pueden vincular.
-- ----------------------------------------------------------------------------
create or replace function public.verificar_cedula_registro(p_id integer)
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_familia public.familias%rowtype;
begin
  select * into v_familia
  from public.familias
  where id = p_id;

  if not found then
    return jsonb_build_object(
      'existe', false,
      'tiene_cuenta', false,
      'bloqueada', false,
      'disponible', true
    );
  end if;

  return jsonb_build_object(
    'existe', true,
    'tiene_cuenta', v_familia.auth_id is not null,
    'bloqueada', v_familia.is_deleted = true,
    'disponible', v_familia.auth_id is null and v_familia.is_deleted = false,
    'id_calle', v_familia.id_calle
  );
end;
$$;

revoke all on function public.verificar_cedula_registro(integer) from public;
grant execute on function public.verificar_cedula_registro(integer) to anon, authenticated;

-- ----------------------------------------------------------------------------
-- 7. RPC · Registro público / vinculación de cuenta a una familia ya censada.
--    Reemplaza la versión anterior para:
--      - Vincular la cuenta a una familia existente que aún no tiene auth_id.
--      - Verificar que el correo coincida con el registrado por el Jefe de Calle.
--      - Dejar la familia y el Jefe de Familia en estado PENDIENTE.
--      - Notificar al Jefe de Calle.
-- ----------------------------------------------------------------------------
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
  v_familia public.familias%rowtype;
  v_jefe public.jefe_de_calle%rowtype;
  v_notificado boolean := false;
  v_vinculado boolean := false;
  v_nombre text;
  v_email text;
  v_auth_email text;
begin
  if p_auth_id is null then
    raise exception 'La cuenta de acceso es obligatoria.' using errcode = '22023';
  end if;

  -- Si hay una sesión activa, la cuenta debe ser la misma.
  if auth.uid() is not null and auth.uid() <> p_auth_id then
    raise exception 'La cuenta de acceso no coincide con la sesión actual.' using errcode = '42501';
  end if;

  -- Verificar que la cuenta exista y que el correo coincida con el de Auth.
  select lower(u.email) into v_auth_email
  from auth.users u
  where u.id = p_auth_id;

  if v_auth_email is null then
    raise exception 'La cuenta de acceso no existe.' using errcode = '22023';
  end if;

  v_email := nullif(lower(btrim(coalesce(p_email, ''))), '');
  if v_email is not null and v_email <> v_auth_email then
    raise exception 'El correo indicado no coincide con la cuenta de acceso.' using errcode = '22023';
  end if;
  v_email := coalesce(v_email, v_auth_email);

  v_nombre := nullif(btrim(p_nombre), '');
  if v_nombre is null then
    raise exception 'El nombre de la familia es obligatorio.' using errcode = '22023';
  end if;

  if p_id_calle is null or not exists (
    select 1
    from public.calles c
    where c.id_calle = p_id_calle
      and c.is_deleted = false
  ) then
    raise exception 'La calle seleccionada no existe o fue dada de baja.' using errcode = '22023';
  end if;

  select * into v_familia
  from public.familias
  where id = p_id
  for update;

  if found then
    if v_familia.is_deleted then
      raise exception 'Esta familia fue dada de baja. Contacta al Jefe de Calle.'
        using errcode = 'P0001';
    end if;

    if v_familia.auth_id is not null then
      raise exception 'Esta cédula ya tiene una cuenta de acceso. Inicia sesión o recupera tu contraseña.'
        using errcode = 'P0001';
    end if;

    if v_familia.id_calle is not null and v_familia.id_calle <> p_id_calle then
      raise exception 'Esta cédula ya está registrada en otra calle. Contacta al Jefe de Calle.'
        using errcode = 'P0001';
    end if;

    -- Si el Jefe de Calle registró un correo de contacto, debe coincidir.
    if v_familia.email is not null
       and lower(btrim(v_familia.email)) <> v_email then
      raise exception
        'El correo no coincide con el registrado por el Jefe de Calle. Usa el mismo correo o contacta a tu Jefe de Calle.'
        using errcode = 'P0001';
    end if;

    if exists (
      select 1
      from public.familias f
      where f.auth_id = p_auth_id
        and f.id <> p_id
        and f.is_deleted = false
    ) then
      raise exception 'Esta cuenta ya está vinculada a otra familia.' using errcode = 'P0001';
    end if;

    if exists (
      select 1
      from public.jefes_familia j
      where j.auth_id = p_auth_id
        and j.id_familia <> p_id
        and j.activo = true
        and j.is_deleted = false
    ) then
      raise exception 'Esta cuenta ya es Jefe de Familia de otra familia.' using errcode = 'P0001';
    end if;

    -- Autoriza al trigger de protección a aceptar únicamente este cambio de
    -- auth_id durante esta transacción.
    perform set_config('sigas.vinculando_cuenta', p_auth_id::text, true);

    update public.familias
    set auth_id = p_auth_id,
        email = coalesce(email, v_email),
        id_calle = coalesce(id_calle, p_id_calle),
        estado = 'pendiente',
        activo = false,
        notas_rechazo = null,
        updated_at = now()
    where id = p_id;

    -- Vincular la cuenta solo al registro vigente del Jefe de Familia, si
    -- existe. No se tocan los registros históricos ni los ya dados de baja.
    update public.jefes_familia
    set auth_id = p_auth_id,
        estado = 'pendiente',
        activo = false,
        updated_at = now()
    where id_jefe_familia = (
      select j.id_jefe_familia
      from public.jefes_familia j
      where j.id_familia = p_id
        and j.is_deleted = false
      order by j.activo desc, j.created_at desc
      limit 1
    );

    perform set_config('sigas.vinculando_cuenta', '', true);

    v_vinculado := true;
  else
    if exists (
      select 1
      from public.familias f
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
      nullif(regexp_replace(coalesce(p_telefono, ''), '\D', '', 'g'), ''),
      nullif(btrim(p_direccion), ''),
      p_personas,
      v_email,
      false
    );
  end if;

  -- Notificar al Jefe de Calle de la zona.
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
      case when v_vinculado then 'Cuenta vinculada pendiente' else 'Nuevo registro pendiente' end,
      format(
        'La familia %s (cédula %s) %s en tu calle.',
        v_nombre,
        p_id,
        case
          when v_vinculado then 'solicitó vincular su cuenta de acceso y quedó pendiente'
          else 'solicitó registro'
        end
      ),
      jsonb_build_object(
        'id_familia', p_id,
        'id_calle', p_id_calle,
        'email', v_email,
        'vinculado', v_vinculado
      )
    );
    v_notificado := true;
  end if;

  return jsonb_build_object(
    'ok', true,
    'id_familia', p_id,
    'notificado', v_notificado,
    'vinculado', v_vinculado
  );
exception
  when unique_violation then
    raise exception
      'Ya existe un registro con esa cédula o esa cuenta ya está vinculada a otra familia.'
      using errcode = '23505';
end;
$$;

grant execute on function public.registrar_familia_pendiente(integer, uuid, text, integer, text, text, integer, text)
  to anon, authenticated;

-- ----------------------------------------------------------------------------
-- 7.1 RPC · Vincular una cuenta existente a una familia ya censada.
--     Se usa cuando la persona ya tenía una cuenta de Authentication antes de
--     que el Jefe de Calle la registrara. La coincidencia se hace por el correo
--     de la sesión autenticada, nunca por un correo enviado por el cliente.
-- ----------------------------------------------------------------------------
create or replace function public.vincular_cuenta_familia()
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_auth_id uuid := auth.uid();
  v_email text;
  v_familia public.familias%rowtype;
  v_jefe public.jefe_de_calle%rowtype;
  v_total integer;
  v_notificado boolean := false;
begin
  if v_auth_id is null then
    raise exception 'Debes iniciar sesión para vincular tu cuenta.' using errcode = '42501';
  end if;

  select lower(u.email) into v_email
  from auth.users u
  where u.id = v_auth_id;

  if v_email is null then
    raise exception 'La cuenta no tiene un correo asociado.' using errcode = '22023';
  end if;

  select count(*) into v_total
  from public.familias f
  where lower(btrim(f.email)) = v_email
    and f.auth_id is null
    and f.id_cargo = 3
    and f.is_deleted = false;

  if v_total = 0 then
    return jsonb_build_object('ok', true, 'vinculado', false);
  end if;

  if v_total > 1 then
    raise exception 'Hay más de una familia registrada con tu correo. Contacta al administrador.'
      using errcode = 'P0001';
  end if;

  select * into v_familia
  from public.familias f
  where lower(btrim(f.email)) = v_email
    and f.auth_id is null
    and f.id_cargo = 3
    and f.is_deleted = false
  for update;

  if not found then
    return jsonb_build_object('ok', true, 'vinculado', false);
  end if;

  -- La cuenta no puede estar ya vinculada a otra familia.
  if exists (
    select 1
    from public.familias f
    where f.auth_id = v_auth_id
      and f.is_deleted = false
  ) then
    return jsonb_build_object('ok', true, 'vinculado', false);
  end if;

  -- La cuenta no puede ser Jefe de Familia activo de otra familia.
  if exists (
    select 1
    from public.jefes_familia j
    where j.auth_id = v_auth_id
      and j.activo = true
      and j.is_deleted = false
  ) then
    return jsonb_build_object('ok', true, 'vinculado', false);
  end if;

  perform set_config('sigas.vinculando_cuenta', v_auth_id::text, true);

  update public.familias
  set auth_id = v_auth_id,
      estado = 'pendiente',
      activo = false,
      notas_rechazo = null,
      updated_at = now()
  where id = v_familia.id;

  update public.jefes_familia
  set auth_id = v_auth_id,
      estado = 'pendiente',
      activo = false,
      updated_at = now()
  where id_jefe_familia = (
    select j.id_jefe_familia
    from public.jefes_familia j
    where j.id_familia = v_familia.id
      and j.is_deleted = false
    order by j.activo desc, j.created_at desc
    limit 1
  );

  perform set_config('sigas.vinculando_cuenta', '', true);

  -- Notificar al Jefe de Calle de la zona.
  select j.* into v_jefe
  from public.jefe_de_calle j
  where j.id_calle = v_familia.id_calle
    and j.activo = true
    and j.is_deleted = false
  order by j.id_jefe_calle
  limit 1;

  if v_jefe.id_jefe_calle is null then
    select j.* into v_jefe
    from public.calles c
    join public.jefe_de_calle j on j.id_jefe_calle = c.id_jefe_calle
    where c.id_calle = v_familia.id_calle
      and j.activo = true
      and j.is_deleted = false
    order by j.id_jefe_calle
    limit 1;
  end if;

  if v_jefe.id_jefe_calle is not null and v_jefe.auth_id is not null then
    perform public.sigas_notificar(
      v_jefe.auth_id,
      v_jefe.id_jefe_calle,
      v_familia.id,
      'registro_familia',
      'Cuenta vinculada pendiente',
      format(
        'La familia %s (cédula %s) vinculó su cuenta existente y quedó pendiente.',
        v_familia.nombre_familia,
        v_familia.id
      ),
      jsonb_build_object(
        'id_familia', v_familia.id,
        'id_calle', v_familia.id_calle,
        'email', v_email,
        'vinculado', true
      )
    );
    v_notificado := true;
  end if;

  return jsonb_build_object(
    'ok', true,
    'vinculado', true,
    'id_familia', v_familia.id,
    'notificado', v_notificado
  );
end;
$$;

revoke all on function public.vincular_cuenta_familia() from public;
grant execute on function public.vincular_cuenta_familia() to authenticated;

-- ----------------------------------------------------------------------------
-- 8. RPC · Aprobar registro. Ahora reutiliza el Jefe de Familia pendiente
--    creado por el Jefe de Calle, en lugar de rechazarlo por existir.
-- ----------------------------------------------------------------------------
create or replace function public.aprobar_registro_familia(p_id_familia integer)
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_familia public.familias%rowtype;
  v_jefe public.jefes_familia%rowtype;
begin
  if not public.sigas_puede_gestionar_familia(p_id_familia) then
    raise exception 'No tienes permiso para aprobar este registro.' using errcode = '42501';
  end if;

  select * into v_familia
  from public.familias
  where id = p_id_familia
    and is_deleted = false
  for update;

  if not found then
    raise exception 'El registro ya no existe o fue eliminado.' using errcode = 'P0002';
  end if;

  if v_familia.id_calle is null then
    raise exception 'La familia no tiene una calle asignada. Un administrador debe asignarla antes de aprobar.'
      using errcode = '23514';
  end if;

  -- Un Jefe de Familia debe tener cuenta de acceso. Si el Jefe de Calle ya
  -- registró los datos, la persona debe completar su registro desde el login.
  if v_familia.auth_id is null then
    raise exception 'La persona todavía no ha creado su cuenta de acceso. Pídele que se registre con su cédula y el correo indicado.'
      using errcode = 'P0001';
  end if;

  select * into v_jefe
  from public.jefes_familia
  where id_familia = p_id_familia
    and is_deleted = false
  order by activo desc, created_at desc
  limit 1
  for update;

  if found then
    if v_jefe.activo and v_jefe.estado = 'aprobado' then
      return jsonb_build_object(
        'ok', true,
        'id_familia', p_id_familia,
        'id_jefe_familia', v_jefe.id_jefe_familia,
        'ya_estaba_aprobado', true
      );
    end if;

    update public.jefes_familia
    set auth_id = coalesce(v_familia.auth_id, v_jefe.auth_id),
        id_calle = v_familia.id_calle,
        nombre = coalesce(nullif(btrim(v_jefe.nombre), ''), v_familia.nombre_familia),
        ci = coalesce(
          nullif(regexp_replace(coalesce(v_jefe.ci, ''), '\D', '', 'g'), ''),
          v_familia.id::text
        ),
        telefono = coalesce(
          nullif(regexp_replace(coalesce(v_jefe.telefono, ''), '\D', '', 'g'), ''),
          v_familia.telefono
        ),
        activo = true,
        estado = 'aprobado',
        updated_at = now()
    where id_jefe_familia = v_jefe.id_jefe_familia
    returning * into v_jefe;
  else
    insert into public.jefes_familia (
      id_familia,
      auth_id,
      id_calle,
      nombre,
      ci,
      telefono,
      activo,
      estado,
      is_deleted
    )
    values (
      v_familia.id,
      v_familia.auth_id,
      v_familia.id_calle,
      v_familia.nombre_familia,
      v_familia.id::text,
      v_familia.telefono,
      true,
      'aprobado',
      false
    )
    returning * into v_jefe;
  end if;

  update public.familias
  set estado = 'aprobado',
      activo = true,
      notas_rechazo = null,
      updated_at = now()
  where id = p_id_familia;

  perform public.sigas_notificar(
    v_familia.auth_id,
    null,
    v_familia.id,
    'registro_aprobado',
    'Registro aprobado',
    'Tu registro como Jefe de Familia fue aprobado. Ya puedes iniciar sesión en SIGAS.',
    jsonb_build_object(
      'id_familia', v_familia.id,
      'id_jefe_familia', v_jefe.id_jefe_familia
    )
  );

  return jsonb_build_object(
    'ok', true,
    'id_familia', v_familia.id,
    'id_jefe_familia', v_jefe.id_jefe_familia
  );
exception
  when unique_violation then
    raise exception 'La familia ya tiene un Jefe de Familia activo. Debes darlo de baja antes de asignar otro.'
      using errcode = '23505';
end;
$$;

grant execute on function public.aprobar_registro_familia(integer) to authenticated;

commit;


-- ############################################################################
-- 3/5 · 20261108_jefes_familia_administracion.sql
-- ############################################################################

-- ============================================================================
-- SIGAS · Administración de Jefes de Familia
-- ----------------------------------------------------------------------------
-- Permite al Jefe de Calle y al administrador editar los datos de contacto
-- del Jefe de Familia sin darlo de baja ni cambiar su cuenta de acceso.
--
-- Esta migración NO borra datos. Solo crea una función nueva.
-- ============================================================================

begin;

create or replace function public.actualizar_jefe_familia(
  p_id_jefe_familia bigint,
  p_nombre text,
  p_telefono text default null,
  p_email text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_jefe public.jefes_familia%rowtype;
  v_nombre text;
  v_telefono text;
  v_email text;
begin
  select * into v_jefe
  from public.jefes_familia
  where id_jefe_familia = p_id_jefe_familia
    and is_deleted = false
  for update;

  if not found then
    raise exception 'El Jefe de Familia ya no existe o fue dado de baja.'
      using errcode = 'P0002';
  end if;

  if not public.sigas_puede_gestionar_calle(v_jefe.id_calle) then
    raise exception 'No tienes permiso para editar a este Jefe de Familia.'
      using errcode = '42501';
  end if;

  v_nombre := nullif(btrim(p_nombre), '');
  if v_nombre is null then
    raise exception 'El nombre del Jefe de Familia es obligatorio.'
      using errcode = '22023';
  end if;

  v_telefono := nullif(regexp_replace(coalesce(p_telefono, ''), '\D', '', 'g'), '');
  v_email := nullif(lower(btrim(coalesce(p_email, ''))), '');

  if v_email is not null
     and v_email !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]{2,}$' then
    raise exception 'El correo del Jefe de Familia no es válido.'
      using errcode = '22023';
  end if;

  update public.jefes_familia
  set nombre = v_nombre,
      telefono = v_telefono,
      updated_at = now()
  where id_jefe_familia = v_jefe.id_jefe_familia
  returning * into v_jefe;

  -- Actualiza el correo de contacto de la familia. No cambia el correo de
  -- Authentication de la persona ni su cuenta de acceso.
  update public.familias
  set email = coalesce(v_email, email),
      updated_at = now()
  where id = v_jefe.id_familia;

  return jsonb_build_object(
    'ok', true,
    'id_jefe_familia', v_jefe.id_jefe_familia,
    'id_familia', v_jefe.id_familia,
    'activo', v_jefe.activo,
    'tiene_cuenta', v_jefe.auth_id is not null
  );
end;
$$;

revoke all on function public.actualizar_jefe_familia(bigint, text, text, text) from public;
grant execute on function public.actualizar_jefe_familia(bigint, text, text, text) to authenticated;

commit;

-- ############################################################################
-- 4/5 · 20261109_jefes_calle_multicalle_autorregistro.sql
-- ############################################################################

-- ============================================================================
-- SIGAS · Jefes de Calle: autorregistro, aprobación y multicalle
-- Fecha: 2026-11-09
-- ----------------------------------------------------------------------------
-- Objetivo:
--   1. Un Jefe de Calle puede tener asignadas VARIAS calles.
--      La relación autoritativa sigue siendo calles.id_jefe_calle.
--      jefe_de_calle.id_calle se conserva como calle principal (primera).
--   2. El Jefe de Calle puede crear su propia cuenta desde el login.
--      La ficha queda en estado 'pendiente' y activo = false hasta que un
--      administrador la apruebe.
--   3. Una cuenta de acceso (auth_id) no puede estar vinculada a la vez a una
--      familia, a un Jefe de Familia y a un Jefe de Calle.
--   4. Una cédula no puede repetirse entre Jefes de Calle vigentes.
--
-- Esta migración NO borra datos. Solo agrega una columna, índices, funciones
-- y triggers. Si encuentra duplicados, se detiene con un mensaje claro.
-- ============================================================================

begin;

-- ----------------------------------------------------------------------------
-- 1. Columnas de contacto del Jefe de Calle.
--    La cuenta real vive en auth.users; estos datos son para mostrarlos al
--    administrador y para validar cédulas duplicadas.
-- ----------------------------------------------------------------------------
alter table public.jefe_de_calle add column if not exists ci text;
alter table public.jefe_de_calle add column if not exists email text;

-- Normaliza cédulas existentes (solo dígitos) para poder compararlas.
update public.jefe_de_calle
set ci = regexp_replace(ci, '\D', '', 'g')
where ci is not null
  and ci <> regexp_replace(ci, '\D', '', 'g');

-- ----------------------------------------------------------------------------
-- 2. Verificación previa de duplicados.
--    Evita que los índices únicos fallen con un error genérico.
-- ----------------------------------------------------------------------------
do $$
declare
  v_dup record;
begin
  for v_dup in
    select
      regexp_replace(ci, '\D', '', 'g') as cedula,
      count(*) as total
    from public.jefe_de_calle
    where ci is not null
      and is_deleted = false
      and regexp_replace(ci, '\D', '', 'g') <> ''
    group by regexp_replace(ci, '\D', '', 'g')
    having count(*) > 1
  loop
    raise exception
      'La cédula % está vinculada a % Jefes de Calle vigentes. Corrige ese duplicado antes de aplicar esta migración.',
      v_dup.cedula, v_dup.total;
  end loop;

  for v_dup in
    select auth_id, count(*) as total
    from public.jefe_de_calle
    where auth_id is not null
      and is_deleted = false
    group by auth_id
    having count(*) > 1
  loop
    raise exception
      'La cuenta % está vinculada a % Jefes de Calle vigentes. Corrige ese duplicado antes de aplicar esta migración.',
      v_dup.auth_id, v_dup.total;
  end loop;
end $$;

-- ----------------------------------------------------------------------------
-- 3. Índices únicos y de apoyo.
-- ----------------------------------------------------------------------------
create unique index if not exists uq_jefe_de_calle_auth_vigente
  on public.jefe_de_calle (auth_id)
  where auth_id is not null
    and is_deleted = false;

create unique index if not exists uq_jefe_de_calle_ci_vigente
  on public.jefe_de_calle (regexp_replace(ci, '\D', '', 'g'))
  where ci is not null
    and is_deleted = false
    and regexp_replace(ci, '\D', '', 'g') <> '';

create index if not exists idx_calles_jefe_calle
  on public.calles (id_jefe_calle)
  where is_deleted = false;

-- ----------------------------------------------------------------------------
-- 4. Una cuenta = un rol.
--    Impide que la misma cuenta de Authentication sea familia y Jefe de Calle
--    (o Jefe de Familia) al mismo tiempo.
-- ----------------------------------------------------------------------------
create or replace function public.sigas_validar_cuenta_exclusiva()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  if new.auth_id is null then
    return new;
  end if;

  if tg_table_name = 'familias' then
    if exists (
      select 1
      from public.jefe_de_calle j
      where j.auth_id = new.auth_id
        and j.is_deleted = false
    ) then
      raise exception 'Esta cuenta ya está vinculada a un Jefe de Calle.'
        using errcode = '23505';
    end if;
  elsif tg_table_name = 'jefe_de_calle' then
    if exists (
      select 1
      from public.familias f
      where f.auth_id = new.auth_id
        and f.is_deleted = false
    ) then
      raise exception 'Esta cuenta ya está vinculada a una familia.'
        using errcode = '23505';
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_familias_cuenta_exclusiva on public.familias;
create trigger trg_familias_cuenta_exclusiva
before insert or update of auth_id on public.familias
for each row execute function public.sigas_validar_cuenta_exclusiva();

drop trigger if exists trg_jefe_de_calle_cuenta_exclusiva on public.jefe_de_calle;
create trigger trg_jefe_de_calle_cuenta_exclusiva
before insert or update of auth_id on public.jefe_de_calle
for each row execute function public.sigas_validar_cuenta_exclusiva();

-- ----------------------------------------------------------------------------
-- 5. RPC · Verificar cédula antes de crear la cuenta de Authentication.
--    Se usa desde el autorregistro para no dejar cuentas huérfanas.
-- ----------------------------------------------------------------------------
create or replace function public.verificar_cedula_jefe_calle(p_ci text)
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_ci text := regexp_replace(coalesce(p_ci, ''), '\D', '', 'g');
  v_jefe public.jefe_de_calle%rowtype;
  v_en_familias boolean := false;
begin
  if length(v_ci) < 5 or length(v_ci) > 10 then
    raise exception 'La cédula del Jefe de Calle no es válida.' using errcode = '22023';
  end if;

  select exists (
    select 1
    from public.familias f
    where f.id = v_ci::integer
      and f.is_deleted = false
  ) into v_en_familias;

  select * into v_jefe
  from public.jefe_de_calle j
  where regexp_replace(coalesce(j.ci, ''), '\D', '', 'g') = v_ci
    and j.is_deleted = false
  order by j.id_jefe_calle
  limit 1;

  if v_jefe.id_jefe_calle is null then
    return jsonb_build_object(
      'existe', false,
      'tiene_cuenta', false,
      'bloqueada', false,
      'disponible', not v_en_familias,
      'en_familias', v_en_familias
    );
  end if;

  return jsonb_build_object(
    'existe', true,
    'tiene_cuenta', v_jefe.auth_id is not null,
    'bloqueada', false,
    'disponible', v_jefe.auth_id is null,
    'estado', v_jefe.estado,
    'en_familias', v_en_familias
  );
exception
  when invalid_text_representation or numeric_value_out_of_range then
    raise exception 'La cédula del Jefe de Calle no es válida.' using errcode = '22023';
end;
$$;

-- ----------------------------------------------------------------------------
-- 6. RPC · Autorregistro de Jefe de Calle.
--    Crea o vincula la ficha por cédula y la deja PENDIENTE.
--    La cuenta de Authentication ya fue creada por el cliente (signUp).
-- ----------------------------------------------------------------------------
create or replace function public.registrar_jefe_calle_pendiente(
  p_nombre text,
  p_ci text,
  p_auth_id uuid,
  p_telefono text default null,
  p_email text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_jefe public.jefe_de_calle%rowtype;
  v_nombre text;
  v_ci text;
  v_telefono text;
  v_email text;
  v_auth_email text;
  v_notificados integer := 0;
begin
  if p_auth_id is null then
    raise exception 'La cuenta de acceso es obligatoria.' using errcode = '22023';
  end if;

  if auth.uid() is not null and auth.uid() <> p_auth_id then
    raise exception 'La cuenta de acceso no coincide con la sesión actual.'
      using errcode = '42501';
  end if;

  select lower(u.email) into v_auth_email
  from auth.users u
  where u.id = p_auth_id;

  if v_auth_email is null then
    raise exception 'La cuenta de acceso no existe.' using errcode = '22023';
  end if;

  v_email := nullif(lower(btrim(coalesce(p_email, ''))), '');
  if v_email is not null and v_email <> v_auth_email then
    raise exception 'El correo indicado no coincide con la cuenta de acceso.'
      using errcode = '22023';
  end if;
  v_email := coalesce(v_email, v_auth_email);

  v_nombre := nullif(btrim(p_nombre), '');
  if v_nombre is null then
    raise exception 'El nombre del Jefe de Calle es obligatorio.' using errcode = '22023';
  end if;

  v_ci := regexp_replace(coalesce(p_ci, ''), '\D', '', 'g');
  if length(v_ci) < 5 or length(v_ci) > 10 then
    raise exception 'La cédula del Jefe de Calle no es válida.' using errcode = '22023';
  end if;

  v_telefono := nullif(regexp_replace(coalesce(p_telefono, ''), '\D', '', 'g'), '');

  -- La cuenta no puede tener ya otro rol.
  if exists (
    select 1 from public.familias f
    where f.auth_id = p_auth_id
      and f.is_deleted = false
  ) then
    raise exception 'Esta cuenta ya está vinculada a una familia. Usa otra cuenta.'
      using errcode = 'P0001';
  end if;

  if exists (
    select 1 from public.jefes_familia jf
    where jf.auth_id = p_auth_id
      and jf.is_deleted = false
  ) then
    raise exception 'Esta cuenta ya está vinculada a un Jefe de Familia. Usa otra cuenta.'
      using errcode = 'P0001';
  end if;

  if exists (
    select 1 from public.jefe_de_calle j
    where j.auth_id = p_auth_id
      and j.is_deleted = false
  ) then
    raise exception 'Esta cuenta ya está registrada como Jefe de Calle. Inicia sesión o recupera tu contraseña.'
      using errcode = 'P0001';
  end if;

  -- Si el administrador ya había creado la ficha por cédula, se vincula.
  select * into v_jefe
  from public.jefe_de_calle j
  where regexp_replace(coalesce(j.ci, ''), '\D', '', 'g') = v_ci
    and j.is_deleted = false
  order by j.id_jefe_calle
  limit 1
  for update;

  if found then
    if v_jefe.auth_id is not null then
      raise exception 'Esta cédula ya tiene una cuenta de acceso. Inicia sesión o recupera tu contraseña.'
        using errcode = 'P0001';
    end if;

    update public.jefe_de_calle
    set auth_id = p_auth_id,
        nombre = v_nombre,
        ci = v_ci,
        telefono = v_telefono,
        email = v_email,
        estado = 'pendiente',
        activo = false,
        is_deleted = false,
        deleted_at = null
    where id_jefe_calle = v_jefe.id_jefe_calle
    returning * into v_jefe;
  else
    insert into public.jefe_de_calle (
      auth_id,
      nombre,
      ci,
      telefono,
      email,
      estado,
      activo,
      is_deleted
    )
    values (
      p_auth_id,
      v_nombre,
      v_ci,
      v_telefono,
      v_email,
      'pendiente',
      false,
      false
    )
    returning * into v_jefe;
  end if;

  -- Avisa a los administradores para que revisen la solicitud.
  insert into public.notificaciones (
    destinatario_auth_id,
    id_jefe_calle,
    tipo,
    titulo,
    mensaje,
    metadata
  )
  select
    f.auth_id,
    v_jefe.id_jefe_calle,
    'registro_jefe_calle',
    'Nueva solicitud de Jefe de Calle',
    format(
      'El ciudadano %s (cédula %s) solicitó ser Jefe de Calle. Código %s.',
      v_nombre,
      v_ci,
      coalesce(v_jefe.codigo, '—')
    ),
    jsonb_build_object(
      'id_jefe_calle', v_jefe.id_jefe_calle,
      'ci', v_ci,
      'email', v_email
    )
  from public.familias f
  join auth.users u on u.id = f.auth_id
  where f.id_cargo = 1
    and f.activo = true
    and f.is_deleted = false;

  get diagnostics v_notificados = row_count;

  return jsonb_build_object(
    'ok', true,
    'id_jefe_calle', v_jefe.id_jefe_calle,
    'codigo', v_jefe.codigo,
    'estado', v_jefe.estado,
    'notificado', v_notificados > 0
  );
end;
$$;

-- ----------------------------------------------------------------------------
-- 7. Sincronización de calles de un Jefe de Calle (multicalle).
--    Solo administradores. La primera calle del arreglo queda como principal.
-- ----------------------------------------------------------------------------
create or replace function public.sigas_sincronizar_calles_jefe(
  p_id_jefe_calle integer,
  p_ids_calles integer[]
)
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_ids integer[] := coalesce(p_ids_calles, '{}'::integer[]);
  v_id integer;
  v_ocupante public.jefe_de_calle%rowtype;
  v_principal integer;
begin
  if not public.sigas_es_admin() then
    raise exception 'No tienes permiso para asignar calles.' using errcode = '42501';
  end if;

  if not exists (
    select 1
    from public.jefe_de_calle j
    where j.id_jefe_calle = p_id_jefe_calle
      and j.is_deleted = false
  ) then
    raise exception 'El Jefe de Calle no existe o fue dado de baja.' using errcode = 'P0002';
  end if;

  foreach v_id in array v_ids loop
    if not exists (
      select 1
      from public.calles c
      where c.id_calle = v_id
        and c.is_deleted = false
    ) then
      raise exception 'La calle % no existe o fue dada de baja.', v_id using errcode = '22023';
    end if;

    select j.* into v_ocupante
    from public.calles c
    join public.jefe_de_calle j on j.id_jefe_calle = c.id_jefe_calle
    where c.id_calle = v_id
      and j.id_jefe_calle <> p_id_jefe_calle
      and j.activo = true
      and j.is_deleted = false
    limit 1;

    if v_ocupante.id_jefe_calle is not null then
      raise exception 'La calle % ya está asignada a %.',
        v_id, coalesce(v_ocupante.nombre, 'otro Jefe de Calle activo')
        using errcode = '23505';
    end if;
  end loop;

  -- Libera solo las calles que este jefe tenía y ya no fueron seleccionadas.
  update public.calles
  set id_jefe_calle = null
  where id_jefe_calle = p_id_jefe_calle
    and not (id_calle = any(v_ids));

  if array_length(v_ids, 1) is not null then
    update public.calles
    set id_jefe_calle = p_id_jefe_calle
    where id_calle = any(v_ids);
  end if;

  v_principal := case
    when array_length(v_ids, 1) is null then null
    else v_ids[1]
  end;

  update public.jefe_de_calle
  set id_calle = v_principal
  where id_jefe_calle = p_id_jefe_calle;

  return jsonb_build_object(
    'ok', true,
    'id_jefe_calle', p_id_jefe_calle,
    'id_calle', v_principal,
    'id_calles', to_jsonb(v_ids)
  );
end;
$$;

-- ----------------------------------------------------------------------------
-- 8. RPC · Asignar varias calles (edición normal del administrador).
-- ----------------------------------------------------------------------------
create or replace function public.asignar_calles_jefe_calle(
  p_id_jefe_calle integer,
  p_ids_calles integer[]
)
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  return public.sigas_sincronizar_calles_jefe(p_id_jefe_calle, p_ids_calles);
end;
$$;

-- ----------------------------------------------------------------------------
-- 9. RPC · Aprobar Jefe de Calle y asignarle una o varias calles.
--    Exige que la persona ya tenga cuenta de acceso.
-- ----------------------------------------------------------------------------
create or replace function public.aprobar_jefe_calle(
  p_id_jefe_calle integer,
  p_ids_calles integer[] default '{}'::integer[]
)
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_jefe public.jefe_de_calle%rowtype;
  v_sync jsonb;
begin
  if not public.sigas_es_admin() then
    raise exception 'No tienes permiso para aprobar Jefes de Calle.' using errcode = '42501';
  end if;

  select * into v_jefe
  from public.jefe_de_calle
  where id_jefe_calle = p_id_jefe_calle
  for update;

  if not found or v_jefe.is_deleted then
    raise exception 'El Jefe de Calle no existe o fue dado de baja.' using errcode = 'P0002';
  end if;

  if v_jefe.auth_id is null then
    raise exception
      'La persona todavía no ha creado su cuenta de acceso. Debe registrarse como Jefe de Calle desde el inicio de sesión.'
      using errcode = '23514';
  end if;

  v_sync := public.sigas_sincronizar_calles_jefe(p_id_jefe_calle, p_ids_calles);

  update public.jefe_de_calle
  set estado = 'aprobado',
      activo = true,
      deleted_at = null
  where id_jefe_calle = p_id_jefe_calle;

  return jsonb_build_object(
    'ok', true,
    'id_jefe_calle', p_id_jefe_calle,
    'id_calle', v_sync->'id_calle',
    'id_calles', v_sync->'id_calles'
  );
end;
$$;

-- ----------------------------------------------------------------------------
-- 10. RPC · Rechazar una solicitud de Jefe de Calle.
--     Conserva la ficha para que el administrador pueda reconsiderarla.
-- ----------------------------------------------------------------------------
create or replace function public.rechazar_jefe_calle(
  p_id_jefe_calle integer,
  p_motivo text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_jefe public.jefe_de_calle%rowtype;
begin
  if not public.sigas_es_admin() then
    raise exception 'No tienes permiso para rechazar Jefes de Calle.' using errcode = '42501';
  end if;

  select * into v_jefe
  from public.jefe_de_calle
  where id_jefe_calle = p_id_jefe_calle
  for update;

  if not found or v_jefe.is_deleted then
    raise exception 'El Jefe de Calle no existe o fue dado de baja.' using errcode = 'P0002';
  end if;

  update public.calles
  set id_jefe_calle = null
  where id_jefe_calle = p_id_jefe_calle;

  update public.jefe_de_calle
  set estado = 'rechazado',
      activo = false,
      id_calle = null
  where id_jefe_calle = p_id_jefe_calle;

  if v_jefe.auth_id is not null then
    perform public.sigas_notificar(
      v_jefe.auth_id,
      v_jefe.id_jefe_calle,
      null,
      'solicitud_jefe_calle',
      'Solicitud de Jefe de Calle rechazada',
      coalesce(
        nullif(btrim(p_motivo), ''),
        'Tu solicitud para ser Jefe de Calle fue rechazada. Contacta al administrador para más información.'
      ),
      jsonb_build_object('id_jefe_calle', v_jefe.id_jefe_calle)
    );
  end if;

  return jsonb_build_object('ok', true, 'id_jefe_calle', p_id_jefe_calle);
end;
$$;

-- ----------------------------------------------------------------------------
-- 10b. Endurecer sigas_notificar para destinatarios inexistentes.
--      Evita que una notificación a una cuenta eliminada rompa la operación
--      completa (por ejemplo, el autorregistro de un Jefe de Calle).
-- ----------------------------------------------------------------------------
create or replace function public.sigas_notificar(
  p_destinatario_auth_id uuid,
  p_id_jefe_calle integer,
  p_id_familia integer,
  p_tipo text,
  p_titulo text,
  p_mensaje text,
  p_metadata jsonb default '{}'::jsonb
)
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  if p_destinatario_auth_id is null then
    return;
  end if;

  -- La FK de notificaciones apunta a auth.users. Si la cuenta ya no existe,
  -- se omite la notificación en lugar de fallar toda la transacción.
  if not exists (
    select 1
    from auth.users u
    where u.id = p_destinatario_auth_id
  ) then
    return;
  end if;

  insert into public.notificaciones (
    destinatario_auth_id,
    id_jefe_calle,
    id_familia,
    tipo,
    titulo,
    mensaje,
    metadata
  )
  values (
    p_destinatario_auth_id,
    p_id_jefe_calle,
    p_id_familia,
    p_tipo,
    p_titulo,
    p_mensaje,
    coalesce(p_metadata, '{}'::jsonb)
  );
end;
$$;

revoke all on function public.sigas_notificar(uuid, integer, integer, text, text, text, jsonb)
  from public;

-- ----------------------------------------------------------------------------
-- 11. Permisos.
-- ----------------------------------------------------------------------------
grant execute on function public.verificar_cedula_jefe_calle(text) to anon, authenticated;
grant execute on function public.registrar_jefe_calle_pendiente(text, text, uuid, text, text)
  to anon, authenticated;
grant execute on function public.asignar_calles_jefe_calle(integer, integer[]) to authenticated;
grant execute on function public.aprobar_jefe_calle(integer, integer[]) to authenticated;
grant execute on function public.rechazar_jefe_calle(integer, text) to authenticated;

revoke all on function public.sigas_sincronizar_calles_jefe(integer, integer[]) from public;
revoke all on function public.sigas_validar_cuenta_exclusiva() from public;

commit;

-- ############################################################################
-- 5/5 · 20261110_fix_cambio_rol_jefe.sql
-- ############################################################################

-- ============================================================================
-- SIGAS · Fix: el administrador no puede cambiar el rol a Jefe de Calle
-- Fecha: 2026-11-10
-- ----------------------------------------------------------------------------
-- Problema:
--   Al cambiar `familias.id_cargo` a 2 (Jefe de Calle), el trigger
--   `gestionar_cargo_jefe` inserta/actualiza la ficha en `jefe_de_calle`.
--   El trigger de exclusividad veía la misma cuenta en `familias` y lanzaba:
--       "Esta cuenta ya está vinculada a una familia."
--
-- Solución:
--   1. Una fila de `familias` con id_cargo = 2 y una fila de
--      `jefe_de_calle` con el mismo auth_id son el MISMO rol, no un conflicto.
--      Se permite esa combinación; se sigue bloqueando familia/Jefe de Familia
--      contra Jefe de Calle.
--   2. `gestionar_cargo_jefe` pasa a ser AFTER INSERT OR UPDATE. Así, cuando
--      se valida la ficha de Jefe de Calle, la fila de `familias` ya tiene
--      id_cargo = 2.
--   3. Al quitar el rol de Jefe de Calle se hace baja lógica
--      (is_deleted = true, activo = false), se liberan sus calles y NO se
--      borra el historial.
--   4. Se reutiliza la ficha existente por auth_id o por cédula, incluso si
--      estaba dada de baja, para no crear duplicados.
--
-- Es idempotente: se puede ejecutar varias veces.
-- No borra datos.
-- ============================================================================

begin;

-- ----------------------------------------------------------------------------
-- 1. Quitar cualquier trigger de `familias` que use la función vieja.
--    En producción el trigger puede tener un nombre distinto a
--    `trg_gestionar_cargo_jefe`; se busca por la función que ejecuta.
-- ----------------------------------------------------------------------------
do $$
declare
  v_trigger record;
begin
  for v_trigger in
    select t.tgname
    from pg_trigger t
    join pg_proc p on p.oid = t.tgfoid
    join pg_namespace n on n.oid = p.pronamespace
    where t.tgrelid = 'public.familias'::regclass
      and not t.tgisinternal
      and n.nspname = 'public'
      and p.proname = 'gestionar_cargo_jefe'
  loop
    execute format('drop trigger if exists %I on public.familias', v_trigger.tgname);
  end loop;
end $$;

-- ----------------------------------------------------------------------------
-- 2. Regla de exclusividad de cuenta.
--    - familias.id_cargo = 2 + jefe_de_calle con el mismo auth_id: permitido.
--    - familias.id_cargo distinto de 2 + jefe_de_calle: bloqueado.
--    - jefe_de_calle + familias.id_cargo distinto de 2: bloqueado.
--    - Si la ficha de Jefe de Calle ya tiene cédula, debe coincidir con el id
--      de la familia (la cédula es el id de `familias`).
-- ----------------------------------------------------------------------------
create or replace function public.sigas_validar_cuenta_exclusiva()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_ci text;
begin
  if new.auth_id is null then
    return new;
  end if;

  if tg_table_name = 'familias' then
    if coalesce(new.id_cargo, 3) = 2 then
      v_ci := nullif(ltrim(regexp_replace(coalesce(new.id::text, ''), '\D', '', 'g'), '0'), '');

      if exists (
        select 1
        from public.jefe_de_calle j
        where j.auth_id = new.auth_id
          and j.is_deleted = false
          and nullif(ltrim(regexp_replace(coalesce(j.ci, ''), '\D', '', 'g'), '0'), '') is not null
          and nullif(ltrim(regexp_replace(coalesce(j.ci, ''), '\D', '', 'g'), '0'), '') <> v_ci
      ) then
        raise exception 'Esta cuenta ya está vinculada a otro Jefe de Calle.'
          using errcode = '23505';
      end if;
    else
      if exists (
        select 1
        from public.jefe_de_calle j
        where j.auth_id = new.auth_id
          and j.is_deleted = false
      ) then
        raise exception 'Esta cuenta ya está vinculada a un Jefe de Calle.'
          using errcode = '23505';
      end if;
    end if;
  elsif tg_table_name = 'jefe_de_calle' then
    if exists (
      select 1
      from public.familias f
      where f.auth_id = new.auth_id
        and f.is_deleted = false
        and coalesce(f.id_cargo, 3) <> 2
    ) then
      raise exception 'Esta cuenta ya está vinculada a una familia.'
        using errcode = '23505';
    end if;

    v_ci := nullif(ltrim(regexp_replace(coalesce(new.ci, ''), '\D', '', 'g'), '0'), '');

    if v_ci is not null and exists (
      select 1
      from public.familias f
      where f.auth_id = new.auth_id
        and f.is_deleted = false
        and f.id_cargo = 2
        and f.id::text <> v_ci
    ) then
      raise exception 'Esta cuenta ya está vinculada a otro Jefe de Calle.'
        using errcode = '23505';
    end if;
  end if;

  return new;
end;
$$;

-- Recrear los triggers para asegurar que apunten a la función actualizada.
drop trigger if exists trg_familias_cuenta_exclusiva on public.familias;
create trigger trg_familias_cuenta_exclusiva
before insert or update of auth_id on public.familias
for each row execute function public.sigas_validar_cuenta_exclusiva();

drop trigger if exists trg_jefe_de_calle_cuenta_exclusiva on public.jefe_de_calle;
create trigger trg_jefe_de_calle_cuenta_exclusiva
before insert or update of auth_id on public.jefe_de_calle
for each row execute function public.sigas_validar_cuenta_exclusiva();

-- ----------------------------------------------------------------------------
-- 3. Sincronización del cargo.
--    AFTER INSERT OR UPDATE: cuando corre, `familias` ya tiene el nuevo
--    id_cargo y la validación de exclusividad no confunde los dos registros.
-- ----------------------------------------------------------------------------
create or replace function public.gestionar_cargo_jefe()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_jefe public.jefe_de_calle%rowtype;
  v_duplicado public.jefe_de_calle%rowtype;
  v_ci text;
  v_nombre text;
  v_telefono text;
  v_email text;
  v_old_auth_id uuid;
  v_old_cargo integer;
begin
  if tg_op = 'UPDATE' then
    v_old_auth_id := old.auth_id;
    v_old_cargo := old.id_cargo;
  end if;

  v_ci := nullif(ltrim(regexp_replace(coalesce(new.id::text, ''), '\D', '', 'g'), '0'), '');
  v_nombre := coalesce(
    nullif(btrim(new.nombre_familia), ''),
    'Jefe de Calle ' || coalesce(v_ci, new.id::text)
  );
  v_telefono := nullif(regexp_replace(coalesce(new.telefono, ''), '\D', '', 'g'), '');
  v_email := nullif(lower(btrim(coalesce(new.email, ''))), '');

  if new.id_cargo = 2 then
    -- Sin cuenta no se puede crear la ficha de Jefe de Calle.
    if new.auth_id is null then
      return new;
    end if;

    -- Buscar una ficha existente por cuenta nueva, cuenta anterior o cédula.
    -- Se prefieren las fichas vigentes; si no hay, se reutiliza una dada de baja.
    select j.* into v_jefe
    from public.jefe_de_calle j
    where j.auth_id = new.auth_id
       or (v_old_auth_id is not null and j.auth_id = v_old_auth_id)
       or (
         v_ci is not null
         and nullif(ltrim(regexp_replace(coalesce(j.ci, ''), '\D', '', 'g'), '0'), '') = v_ci
       )
    order by
      case
        when j.auth_id = new.auth_id then 0
        when v_ci is not null
             and nullif(ltrim(regexp_replace(coalesce(j.ci, ''), '\D', '', 'g'), '0'), '') = v_ci then 1
        else 2
      end,
      j.is_deleted asc,
      j.id_jefe_calle
    limit 1;

    if v_jefe.id_jefe_calle is null then
      insert into public.jefe_de_calle (
        auth_id,
        nombre,
        ci,
        telefono,
        email,
        id_calle,
        estado,
        activo,
        is_deleted
      )
      values (
        new.auth_id,
        v_nombre,
        v_ci,
        v_telefono,
        v_email,
        new.id_calle,
        'aprobado',
        true,
        false
      )
      returning * into v_jefe;
    else
      -- Si existe otra ficha con la misma cédula, se unifica en la principal
      -- para no violar el índice único de cédula vigente.
      select j.* into v_duplicado
      from public.jefe_de_calle j
      where j.id_jefe_calle <> v_jefe.id_jefe_calle
        and v_ci is not null
        and nullif(ltrim(regexp_replace(coalesce(j.ci, ''), '\D', '', 'g'), '0'), '') = v_ci
      order by j.is_deleted asc, j.id_jefe_calle
      limit 1;

      if v_duplicado.id_jefe_calle is not null then
        update public.calles
        set id_jefe_calle = v_jefe.id_jefe_calle
        where id_jefe_calle = v_duplicado.id_jefe_calle;

        update public.jefe_de_calle
        set is_deleted = true,
            activo = false,
            deleted_at = coalesce(deleted_at, now())
        where id_jefe_calle = v_duplicado.id_jefe_calle;
      end if;

      update public.jefe_de_calle
      set auth_id = new.auth_id,
          nombre = v_nombre,
          ci = coalesce(v_ci, ci),
          telefono = coalesce(v_telefono, telefono),
          email = coalesce(v_email, email),
          id_calle = coalesce(new.id_calle, id_calle, v_duplicado.id_calle),
          estado = 'aprobado',
          activo = true,
          is_deleted = false,
          deleted_at = null
      where id_jefe_calle = v_jefe.id_jefe_calle
      returning * into v_jefe;
    end if;

    -- Si la cuenta cambió, la ficha anterior de esa cuenta deja de ser Jefe.
    if v_old_auth_id is not null and v_old_auth_id is distinct from new.auth_id then
      update public.calles c
      set id_jefe_calle = null
      where c.id_jefe_calle in (
        select j.id_jefe_calle
        from public.jefe_de_calle j
        where j.auth_id = v_old_auth_id
          and j.id_jefe_calle <> v_jefe.id_jefe_calle
      );

      update public.jefe_de_calle j
      set activo = false,
          is_deleted = true,
          deleted_at = coalesce(j.deleted_at, now()),
          id_calle = null
      where j.auth_id = v_old_auth_id
        and j.id_jefe_calle <> v_jefe.id_jefe_calle
        and j.is_deleted = false;
    end if;

    -- Si la calle de la familia está libre, queda como calle principal del
    -- nuevo Jefe de Calle. Si ya tiene otro Jefe activo, no se toca.
    if v_jefe.id_calle is not null then
      update public.calles c
      set id_jefe_calle = v_jefe.id_jefe_calle
      where c.id_calle = v_jefe.id_calle
        and c.is_deleted = false
        and (
          c.id_jefe_calle is null
          or c.id_jefe_calle = v_jefe.id_jefe_calle
          or not exists (
            select 1
            from public.jefe_de_calle otro
            where otro.id_jefe_calle = c.id_jefe_calle
              and otro.activo = true
              and otro.is_deleted = false
          )
        );
    end if;
  elsif v_old_cargo = 2 then
    -- Baja lógica: liberar calles y desactivar la ficha, sin borrar historial.
    update public.calles c
    set id_jefe_calle = null
    where c.id_jefe_calle in (
      select j.id_jefe_calle
      from public.jefe_de_calle j
      where j.auth_id = new.auth_id
         or (v_old_auth_id is not null and j.auth_id = v_old_auth_id)
         or (
           v_ci is not null
           and nullif(ltrim(regexp_replace(coalesce(j.ci, ''), '\D', '', 'g'), '0'), '') = v_ci
         )
    );

    update public.jefe_de_calle j
    set activo = false,
        is_deleted = true,
        deleted_at = coalesce(j.deleted_at, now()),
        id_calle = null
    where j.is_deleted = false
      and (
        j.auth_id = new.auth_id
        or (v_old_auth_id is not null and j.auth_id = v_old_auth_id)
        or (
          v_ci is not null
          and nullif(ltrim(regexp_replace(coalesce(j.ci, ''), '\D', '', 'g'), '0'), '') = v_ci
        )
      );
  end if;

  return new;
end;
$$;

drop trigger if exists trg_gestionar_cargo_jefe on public.familias;
create trigger trg_gestionar_cargo_jefe
after insert or update of id_cargo, auth_id on public.familias
for each row execute function public.gestionar_cargo_jefe();

commit;

-- ============================================================================
-- Verificación rápida (opcional):
--   select tgname, pg_get_triggerdef(oid)
--   from pg_trigger
--   where tgrelid = 'public.familias'::regclass
--     and not tgisinternal;
--
--   select id, auth_id, nombre_familia, id_cargo, activo, is_deleted
--   from public.familias
--   where id = 31894134;
--
-- Prueba manual:
--   1. En el panel de administrador cambia el rol de un usuario a
--      "Jefe de Calle".
--   2. Verifica que se cree/active su fila en jefe_de_calle:
--        select * from public.jefe_de_calle
--        where auth_id = '<auth_id del usuario>';
--   3. Cambia el rol de vuelta a "Familia" y verifica la baja lógica:
--        is_deleted = true, activo = false.
-- ============================================================================
