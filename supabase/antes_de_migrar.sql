-- ============================================================================
-- SIGAS · Revisión y respaldo ANTES de ejecutar la migración
--
-- Este script NO borra datos de las tablas del sistema.
-- Solo muestra un diagnóstico y crea copias de seguridad en el esquema
-- backup_sigas.
--
-- Ejecútalo completo en Supabase → SQL Editor antes de correr
-- 20261028_sigas_mejoras.sql.
-- ============================================================================

-- ============================================================================
-- 1. DIAGNÓSTICO · Cantidad de filas por tabla
-- ============================================================================
select 'familias' as tabla, count(*) as filas from public.familias
union all
select 'jefe_de_calle', count(*) from public.jefe_de_calle
union all
select 'calles', count(*) from public.calles
union all
select 'cargos', count(*) from public.cargos
union all
select 'pedidos', count(*) from public.pedidos
union all
select 'ciclos_distribucion', count(*) from public.ciclos_distribucion
union all
select 'historial_distribucion', count(*) from public.historial_distribucion
order by tabla;

-- ============================================================================
-- 2. Usuarios existentes sin auth_id
--    Con RLS, un usuario sin auth_id no podrá leer su propio perfil.
--    Esto NO se corrige solo; sirve para detectarlo antes.
-- ============================================================================
select id, nombre_familia, id_cargo, activo
from public.familias
where auth_id is null
order by id;

-- ============================================================================
-- 3. ¿Existen las tablas que retiramos del frontend?
--    Si aparecen, NO se borran con la migración. Solo se conservan.
-- ============================================================================
select table_name
from information_schema.tables
where table_schema = 'public'
  and table_name in ('bombonas', 'auditoria');

-- ============================================================================
-- 4. Políticas RLS actuales
--    Si tienes políticas propias, guarda este resultado antes de continuar.
--    La migración reemplaza las políticas de las tablas que administra.
-- ============================================================================
select tablename, policyname, cmd, roles, qual, with_check
from pg_policies
where schemaname = 'public'
order by tablename, policyname;

-- ============================================================================
-- 5. RESPALDO DE DATOS · Esquema backup_sigas
--    Son copias de solo datos (sin constraints ni triggers).
--    No afectan el funcionamiento de la app.
-- ============================================================================
begin;

create schema if not exists backup_sigas;

drop table if exists backup_sigas.familias;
create table backup_sigas.familias as
  select * from public.familias;

drop table if exists backup_sigas.jefe_de_calle;
create table backup_sigas.jefe_de_calle as
  select * from public.jefe_de_calle;

drop table if exists backup_sigas.calles;
create table backup_sigas.calles as
  select * from public.calles;

drop table if exists backup_sigas.cargos;
create table backup_sigas.cargos as
  select * from public.cargos;

drop table if exists backup_sigas.pedidos;
create table backup_sigas.pedidos as
  select * from public.pedidos;

drop table if exists backup_sigas.ciclos_distribucion;
create table backup_sigas.ciclos_distribucion as
  select * from public.ciclos_distribucion;

drop table if exists backup_sigas.historial_distribucion;
create table backup_sigas.historial_distribucion as
  select * from public.historial_distribucion;

-- Si existen las tablas retiradas, también se respaldan.
do $$
begin
  if to_regclass('public.bombonas') is not null then
    drop table if exists backup_sigas.bombonas;
    create table backup_sigas.bombonas as
      select * from public.bombonas;
  end if;

  if to_regclass('public.auditoria') is not null then
    drop table if exists backup_sigas.auditoria;
    create table backup_sigas.auditoria as
      select * from public.auditoria;
  end if;
end $$;

commit;

select 'Respaldo creado en el esquema backup_sigas' as resultado;

-- Cuando ya hayas verificado que todo funciona, puedes liberar espacio con:
-- drop schema backup_sigas cascade;
