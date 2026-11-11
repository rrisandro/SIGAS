-- ============================================================================
-- SIGAS · Diagnóstico y reparación del administrador
-- ----------------------------------------------------------------------------
-- Ejecuta este script en Supabase → SQL Editor.
--
-- Sirve cuando el panel de administrador muestra un error al cambiar roles:
--   "No tienes permiso para modificar esos campos del registro." (42501)
--
-- La causa habitual es que la fila del administrador en public.familias tiene
-- un auth_id que no coincide con su usuario real de Authentication. Entonces
-- sigas_es_admin() devuelve false y el trigger bloquea el cambio de rol.
--
-- Este script NO borra datos. La reparación automática solo actúa cuando:
--   * la fila es un administrador vigente (id_cargo = 1, is_deleted = false),
--   * su auth_id es nulo o no existe en auth.users,
--   * su email coincide exactamente con un usuario CONFIRMADO de auth.users,
--   * ese usuario de Authentication no está vinculado a otra familia vigente.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Estado de todos los administradores.
--    Revisa la columna "diagnostico". Lo esperado es "OK".
-- ----------------------------------------------------------------------------
select
  f.id,
  f.nombre_familia,
  f.email as email_familia,
  f.auth_id,
  f.id_cargo,
  f.activo,
  f.is_deleted,
  u.email as email_auth,
  u.email_confirmed_at,
  case
    when f.auth_id is null then 'auth_id nulo'
    when u.id is null then 'auth_id no existe en Authentication'
    when f.activo is not true then 'administrador inactivo'
    when f.is_deleted then 'administrador dado de baja'
    else 'OK'
  end as diagnostico
from public.familias f
left join auth.users u on u.id = f.auth_id
where f.id_cargo = 1
order by f.is_deleted, f.id;

-- ----------------------------------------------------------------------------
-- 2. Usuarios de Authentication y la familia vinculada.
--    Úsalo para ubicar el UUID real de tu cuenta de administrador.
-- ----------------------------------------------------------------------------
select
  u.id as auth_id,
  u.email,
  u.email_confirmed_at,
  f.id as id_familia,
  f.nombre_familia,
  f.id_cargo,
  f.activo,
  f.is_deleted
from auth.users u
left join public.familias f
  on f.auth_id = u.id
 and f.is_deleted = false
order by u.created_at desc
limit 50;

-- ----------------------------------------------------------------------------
-- 3. Candidatos a reparación automática (solo lectura).
--    Si aparece tu administrador aquí, la sección 4 lo corrige.
-- ----------------------------------------------------------------------------
select
  f.id as id_familia,
  f.nombre_familia,
  f.email as email_familia,
  f.auth_id as auth_id_actual,
  u.id as auth_id_correcto,
  u.email as email_auth
from public.familias f
join auth.users u
  on lower(u.email) = lower(f.email)
where f.id_cargo = 1
  and f.is_deleted = false
  and u.email_confirmed_at is not null
  and (
    f.auth_id is null
    or not exists (
      select 1 from auth.users au where au.id = f.auth_id
    )
  )
  and not exists (
    select 1
    from public.familias otra
    where otra.auth_id = u.id
      and otra.is_deleted = false
      and otra.id <> f.id
  );

-- ----------------------------------------------------------------------------
-- 4. Reparación automática.
--    Se desactiva temporalmente el trigger de protección porque el SQL Editor
--    se ejecuta como postgres y auth.uid() es nulo. El trigger se vuelve a
--    activar en la misma transacción; si algo falla, todo se revierte.
-- ----------------------------------------------------------------------------
begin;

do $$
begin
  if exists (
    select 1 from pg_trigger
    where tgname = 'trg_familias_proteger_campos'
      and tgrelid = 'public.familias'::regclass
  ) then
    execute 'alter table public.familias disable trigger trg_familias_proteger_campos';
  end if;
end $$;

do $$
declare
  v_fila record;
  v_reparados integer := 0;
begin
  for v_fila in
    select
      f.id,
      f.nombre_familia,
      u.id as auth_id_correcto
    from public.familias f
    join auth.users u
      on lower(u.email) = lower(f.email)
    where f.id_cargo = 1
      and f.is_deleted = false
      and u.email_confirmed_at is not null
      and (
        f.auth_id is null
        or not exists (
          select 1 from auth.users au where au.id = f.auth_id
        )
      )
      and not exists (
        select 1
        from public.familias otra
        where otra.auth_id = u.id
          and otra.is_deleted = false
          and otra.id <> f.id
      )
  loop
    update public.familias
    set auth_id = v_fila.auth_id_correcto,
        activo = true,
        updated_at = now()
    where id = v_fila.id;

    v_reparados := v_reparados + 1;

    raise notice
      'Administrador reparado: id=%, nombre=%, auth_id=%',
      v_fila.id,
      v_fila.nombre_familia,
      v_fila.auth_id_correcto;
  end loop;

  if v_reparados = 0 then
    raise notice
      'No se reparó ningún administrador automáticamente. Usa la sección 5.';
  end if;
end $$;

do $$
begin
  if exists (
    select 1 from pg_trigger
    where tgname = 'trg_familias_proteger_campos'
      and tgrelid = 'public.familias'::regclass
  ) then
    execute 'alter table public.familias enable trigger trg_familias_proteger_campos';
  end if;
end $$;

commit;

-- ----------------------------------------------------------------------------
-- 5. Reparación manual (solo si la sección 4 no encontró el candidato).
--
--    a) Copia el UUID real de tu administrador desde
--       Authentication → Users (o desde la consulta de la sección 2).
--    b) Reemplaza <UUID_REAL> y <ID_FAMILIA> y ejecuta el bloque.
--
--    El bloque desactiva el trigger de protección solo durante la
--    transacción. Es imprescindible porque el SQL Editor no tiene auth.uid().
-- ----------------------------------------------------------------------------
/*
begin;

alter table public.familias disable trigger trg_familias_proteger_campos;

update public.familias
set auth_id = '<UUID_REAL>',
    activo = true,
    is_deleted = false,
    deleted_at = null,
    updated_at = now()
where id = <ID_FAMILIA>;

alter table public.familias enable trigger trg_familias_proteger_campos;

commit;
*/

-- ----------------------------------------------------------------------------
-- 6. Verificación final.
--    Debe devolver tu administrador con diagnostico = 'OK'.
-- ----------------------------------------------------------------------------
select
  f.id,
  f.nombre_familia,
  f.email as email_familia,
  f.auth_id,
  f.id_cargo,
  f.activo,
  f.is_deleted,
  u.email as email_auth,
  case
    when f.auth_id is null then 'auth_id nulo'
    when u.id is null then 'auth_id no existe en Authentication'
    when f.activo is not true then 'administrador inactivo'
    when f.is_deleted then 'administrador dado de baja'
    else 'OK'
  end as diagnostico
from public.familias f
left join auth.users u on u.id = f.auth_id
where f.id_cargo = 1
order by f.is_deleted, f.id;
