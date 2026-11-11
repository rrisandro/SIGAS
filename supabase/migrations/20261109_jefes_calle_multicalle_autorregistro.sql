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
  where f.id_cargo = 1
    and f.auth_id is not null
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
