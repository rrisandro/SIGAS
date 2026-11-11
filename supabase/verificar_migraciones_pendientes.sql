-- ============================================================================
-- SIGAS · Verificación previa a las migraciones pendientes
-- ----------------------------------------------------------------------------
-- Este script es de SOLO LECTURA. No modifica ni borra datos.
--
-- Ejecútalo en Supabase → SQL Editor ANTES de correr
-- `supabase/aplicar_migraciones_pendientes.sql`.
--
-- Si alguna consulta devuelve filas, corrígelas primero. Las migraciones
-- agregan índices únicos y se detienen (sin borrar nada) cuando encuentran
-- duplicados.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. ¿Qué columnas/funciones de las migraciones pendientes ya existen?
-- ----------------------------------------------------------------------------
select table_name, column_name
from information_schema.columns
where table_schema = 'public'
  and (
    (table_name = 'familias' and column_name = 'codigo')
    or (
      table_name = 'jefe_de_calle'
      and column_name in ('codigo', 'ci', 'email')
    )
  )
order by table_name, column_name;

select proname as funcion
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and proname in (
    'registrar_jefe_familia',
    'actualizar_jefe_familia',
    'vincular_cuenta_familia',
    'aprobar_registro_familia',
    'verificar_cedula_registro',
    'verificar_cedula_jefe_calle',
    'registrar_jefe_calle_pendiente',
    'asignar_calles_jefe_calle',
    'aprobar_jefe_calle',
    'rechazar_jefe_calle'
  )
order by proname;

-- ----------------------------------------------------------------------------
-- 2. Cuentas vinculadas a más de una familia vigente.
--    Debe devolver 0 filas.
-- ----------------------------------------------------------------------------
select
  auth_id,
  count(*) as familias,
  array_agg(id order by id) as ids_familias
from public.familias
where auth_id is not null
  and is_deleted = false
group by auth_id
having count(*) > 1;

-- ----------------------------------------------------------------------------
-- 3. Cuentas vinculadas a más de un Jefe de Familia activo.
--    Debe devolver 0 filas.
-- ----------------------------------------------------------------------------
select
  auth_id,
  count(*) as jefes,
  array_agg(id_jefe_familia order by id_jefe_familia) as ids_jefes
from public.jefes_familia
where auth_id is not null
  and activo = true
  and is_deleted = false
group by auth_id
having count(*) > 1;

-- ----------------------------------------------------------------------------
-- 4. Cédulas duplicadas entre Jefes de Familia activos.
--    Debe devolver 0 filas.
-- ----------------------------------------------------------------------------
select
  regexp_replace(ci, '\D', '', 'g') as cedula,
  count(*) as jefes,
  array_agg(id_jefe_familia order by id_jefe_familia) as ids_jefes
from public.jefes_familia
where ci is not null
  and activo = true
  and is_deleted = false
  and regexp_replace(ci, '\D', '', 'g') <> ''
group by regexp_replace(ci, '\D', '', 'g')
having count(*) > 1;

-- ----------------------------------------------------------------------------
-- 5. Familias con más de un Jefe de Familia activo.
--    Debe devolver 0 filas.
-- ----------------------------------------------------------------------------
select
  id_familia,
  count(*) as jefes_activos,
  array_agg(id_jefe_familia order by id_jefe_familia) as ids_jefes
from public.jefes_familia
where activo = true
  and is_deleted = false
group by id_familia
having count(*) > 1;

-- ----------------------------------------------------------------------------
-- 5b. Cédulas duplicadas entre Jefes de Calle vigentes.
--     Debe devolver 0 filas. Si devuelve filas, corrige o da de baja la ficha
--     duplicada antes de aplicar la migración.
--     Se ejecuta con SQL dinámico porque la columna `ci` se agrega en la
--     migración 20261109 y puede no existir todavía.
-- ----------------------------------------------------------------------------
do $$
declare
  v_dup record;
  v_encontrado boolean := false;
begin
  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'jefe_de_calle'
      and column_name = 'ci'
  ) then
    raise notice 'La columna jefe_de_calle.ci aún no existe; no hay cédulas duplicadas que revisar.';
    return;
  end if;

  for v_dup in execute $q$
    select
      regexp_replace(ci, '\D', '', 'g') as cedula,
      count(*) as jefes,
      array_agg(id_jefe_calle order by id_jefe_calle) as ids_jefes
    from public.jefe_de_calle
    where ci is not null
      and is_deleted = false
      and regexp_replace(ci, '\D', '', 'g') <> ''
    group by regexp_replace(ci, '\D', '', 'g')
    having count(*) > 1
  $q$
  loop
    v_encontrado := true;
    raise warning
      'Cédula duplicada en Jefes de Calle: % (jefes: %, ids: %)',
      v_dup.cedula, v_dup.jefes, v_dup.ids_jefes;
  end loop;

  if not v_encontrado then
    raise notice 'Sin cédulas duplicadas entre Jefes de Calle vigentes.';
  end if;
end $$;

-- ----------------------------------------------------------------------------
-- 5c. Cuentas vinculadas a más de un Jefe de Calle vigente.
--     Debe devolver 0 filas.
-- ----------------------------------------------------------------------------
select
  auth_id,
  count(*) as jefes,
  array_agg(id_jefe_calle order by id_jefe_calle) as ids_jefes
from public.jefe_de_calle
where auth_id is not null
  and is_deleted = false
group by auth_id
having count(*) > 1;

-- ----------------------------------------------------------------------------
-- 5d. Cuentas con doble rol: familia y Jefe de Calle vigentes a la vez.
--     Debe devolver 0 filas. La migración agrega un trigger que impide
--     nuevos casos, pero no corrige los existentes.
-- ----------------------------------------------------------------------------
select
  f.auth_id,
  f.id as id_familia,
  j.id_jefe_calle,
  j.nombre as nombre_jefe_calle
from public.familias f
join public.jefe_de_calle j on j.auth_id = f.auth_id
where f.auth_id is not null
  and f.is_deleted = false
  and j.is_deleted = false
order by f.auth_id;

-- ----------------------------------------------------------------------------
-- 6. Familias vigentes sin calle asignada.
--    No impide la migración, pero el Jefe de Calle no podrá registrarles
--    un Jefe de Familia hasta que un administrador les asigne una calle.
-- ----------------------------------------------------------------------------
select id, nombre_familia, id_cargo, estado, activo
from public.familias
where id_calle is null
  and is_deleted = false
order by id;

-- ----------------------------------------------------------------------------
-- 7. Familias censadas antes de que existiera id_cargo (id_cargo nulo).
--    Es informativo: la app ya las muestra en el panel del Jefe de Calle.
-- ----------------------------------------------------------------------------
select
  count(*) as familias_legacy,
  min(id) as id_minimo,
  max(id) as id_maximo
from public.familias
where id_cargo is null
  and is_deleted = false;

-- ----------------------------------------------------------------------------
-- 8. Jefes de Familia activos sin cuenta de acceso.
--    Es informativo: no podrán aprobarse hasta que la persona se registre.
-- ----------------------------------------------------------------------------
select id_jefe_familia, id_familia, nombre, ci
from public.jefes_familia
where activo = true
  and auth_id is null
  and is_deleted = false
order by id_jefe_familia;

-- ----------------------------------------------------------------------------
-- 9. Códigos inválidos o duplicados (solo si la columna codigo ya existe).
--    Debe devolver 0 filas.
-- ----------------------------------------------------------------------------
do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'familias'
      and column_name = 'codigo'
  ) then
    if exists (
      select 1 from public.familias
      where codigo is not null
        and codigo !~ '^[A-Z0-9]{3}$'
    ) then
      raise warning 'Hay códigos de familias con formato inválido (deben ser 3 caracteres A-Z/0-9).';
    end if;
  end if;

  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'jefe_de_calle'
      and column_name = 'codigo'
  ) then
    if exists (
      select 1 from public.jefe_de_calle
      where codigo is not null
        and codigo !~ '^[A-Z0-9]{3}$'
    ) then
      raise warning 'Hay códigos de Jefes de Calle con formato inválido (deben ser 3 caracteres A-Z/0-9).';
    end if;
  end if;
end $$;

-- ============================================================================
-- Si todas las consultas de duplicados devolvieron 0 filas, puedes ejecutar
-- `supabase/aplicar_migraciones_pendientes.sql` completo.
-- ============================================================================
