-- ============================================================================
-- SIGAS · Migración de mejoras
-- Fecha: 2026-10-28
--
-- Incluye:
--   1. Columnas de soft delete y estado para familias, jefes de calle y calles.
--   2. Tabla jefes_familia con la regla: un solo Jefe de Familia activo por familia.
--   3. Tabla notificaciones + Supabase Realtime.
--   4. Tabla bombonas (inventario) con soft delete.
--   5. Tabla auditoria compatible con useAuditoria().
--   6. RPCs usadas por el frontend.
--   7. RLS para todas las tablas del sistema.
--
-- Ejecutar en Supabase → SQL Editor. Es idempotente en la medida de lo posible.
-- ============================================================================

begin;

-- ============================================================================
-- 1. EXTENSIONES
-- ============================================================================
create extension if not exists pgcrypto;

-- ============================================================================
-- 2. COLUMNAS NUEVAS EN TABLAS EXISTENTES
-- ============================================================================

-- ---------------------------------------------------------------------------
-- familias (los usuarios del sistema viven aquí: id_cargo 1=admin, 2=jefe, 3=familia)
-- ---------------------------------------------------------------------------
alter table public.familias add column if not exists telefono text;
alter table public.familias add column if not exists direccion text;
alter table public.familias add column if not exists num_personas integer;
alter table public.familias add column if not exists email text;
alter table public.familias add column if not exists notas_rechazo text;
alter table public.familias add column if not exists estado text;
alter table public.familias add column if not exists is_deleted boolean not null default false;
alter table public.familias add column if not exists deleted_at timestamptz;
alter table public.familias add column if not exists created_at timestamptz not null default now();
alter table public.familias add column if not exists updated_at timestamptz not null default now();

-- Las familias que ya existían se consideran aprobadas. Las nuevas nacen pendientes.
update public.familias set estado = 'aprobado' where estado is null;
alter table public.familias alter column estado set default 'pendiente';
alter table public.familias alter column estado set not null;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'familias_estado_check'
      and conrelid = 'public.familias'::regclass
  ) then
    alter table public.familias
      add constraint familias_estado_check
      check (estado in ('pendiente', 'aprobado', 'rechazado'));
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- jefe_de_calle
-- ---------------------------------------------------------------------------
alter table public.jefe_de_calle add column if not exists id_calle integer;
alter table public.jefe_de_calle add column if not exists telefono text;
alter table public.jefe_de_calle add column if not exists estado text;
alter table public.jefe_de_calle add column if not exists is_deleted boolean not null default false;
alter table public.jefe_de_calle add column if not exists deleted_at timestamptz;
alter table public.jefe_de_calle add column if not exists created_at timestamptz not null default now();
alter table public.jefe_de_calle add column if not exists updated_at timestamptz not null default now();

update public.jefe_de_calle set estado = 'aprobado' where estado is null;
alter table public.jefe_de_calle alter column estado set default 'aprobado';
alter table public.jefe_de_calle alter column estado set not null;

-- Backfill: antes la relación jefe ↔ calle vivía en calles.id_jefe_calle.
update public.jefe_de_calle j
set id_calle = c.id_calle
from public.calles c
where c.id_jefe_calle = j.id_jefe_calle
  and j.id_calle is null;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'jefe_de_calle_estado_check'
      and conrelid = 'public.jefe_de_calle'::regclass
  ) then
    alter table public.jefe_de_calle
      add constraint jefe_de_calle_estado_check
      check (estado in ('pendiente', 'aprobado', 'rechazado'));
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- calles
-- ---------------------------------------------------------------------------
alter table public.calles add column if not exists is_deleted boolean not null default false;
alter table public.calles add column if not exists deleted_at timestamptz;
alter table public.calles add column if not exists created_at timestamptz not null default now();
alter table public.calles add column if not exists updated_at timestamptz not null default now();

-- ---------------------------------------------------------------------------
-- pedidos
-- ---------------------------------------------------------------------------
alter table public.pedidos add column if not exists motivo_rechazo text;
alter table public.pedidos add column if not exists created_at timestamptz not null default now();
alter table public.pedidos add column if not exists updated_at timestamptz not null default now();

-- ---------------------------------------------------------------------------
-- ciclos_distribucion / historial_distribucion
-- ---------------------------------------------------------------------------
alter table public.ciclos_distribucion add column if not exists created_at timestamptz not null default now();
alter table public.ciclos_distribucion add column if not exists updated_at timestamptz not null default now();
alter table public.historial_distribucion add column if not exists created_at timestamptz not null default now();

-- ============================================================================
-- 3. TABLA jefes_familia
--    Regla estricta: una familia solo puede tener un Jefe de Familia activo.
-- ============================================================================
create table if not exists public.jefes_familia (
  id_jefe_familia bigint generated by default as identity primary key,
  id_familia integer not null references public.familias(id) on delete restrict,
  auth_id uuid references auth.users(id) on delete set null,
  id_calle integer references public.calles(id_calle) on delete set null,
  nombre text not null,
  ci text,
  telefono text,
  activo boolean not null default true,
  estado text not null default 'aprobado',
  is_deleted boolean not null default false,
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint jefes_familia_estado_check check (estado in ('pendiente', 'aprobado', 'rechazado'))
);

create unique index if not exists uq_jefes_familia_activo
  on public.jefes_familia (id_familia)
  where activo = true and is_deleted = false;

create index if not exists idx_jefes_familia_calle
  on public.jefes_familia (id_calle)
  where is_deleted = false;

create index if not exists idx_jefes_familia_auth
  on public.jefes_familia (auth_id)
  where is_deleted = false;

-- ============================================================================
-- 4. TABLA notificaciones
-- ============================================================================
create table if not exists public.notificaciones (
  id_notificacion bigint generated by default as identity primary key,
  destinatario_auth_id uuid not null references auth.users(id) on delete cascade,
  id_jefe_calle integer references public.jefe_de_calle(id_jefe_calle) on delete set null,
  id_familia integer references public.familias(id) on delete set null,
  tipo text not null default 'sistema',
  titulo text not null,
  mensaje text not null,
  metadata jsonb not null default '{}'::jsonb,
  leida boolean not null default false,
  leida_at timestamptz,
  is_deleted boolean not null default false,
  deleted_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists idx_notificaciones_destinatario
  on public.notificaciones (destinatario_auth_id, created_at desc);

create index if not exists idx_notificaciones_no_leidas
  on public.notificaciones (destinatario_auth_id)
  where leida = false and is_deleted = false;

-- ============================================================================
-- 5. TABLA bombonas (inventario)
-- ============================================================================
create table if not exists public.bombonas (
  id_bombona bigint generated by default as identity primary key,
  codigo text not null unique,
  tipo_bombona text not null,
  peso_kg numeric(6, 2),
  estado text not null default 'disponible',
  id_calle integer references public.calles(id_calle) on delete set null,
  id_pedido integer references public.pedidos(id_pedido) on delete set null,
  id_ciclo integer references public.ciclos_distribucion(id_ciclo) on delete set null,
  observaciones text,
  is_deleted boolean not null default false,
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint bombonas_tipo_check check (tipo_bombona in ('10kg', '18kg', '43kg')),
  constraint bombonas_estado_check check (estado in ('disponible', 'asignada', 'entregada', 'mantenimiento', 'perdida'))
);

create index if not exists idx_bombonas_calle
  on public.bombonas (id_calle)
  where is_deleted = false;

create index if not exists idx_bombonas_estado
  on public.bombonas (estado)
  where is_deleted = false;

-- ============================================================================
-- 6. TABLA auditoria (compatible con src/composables/useAuditoria.js)
-- ============================================================================
create table if not exists public.auditoria (
  id bigint generated by default as identity primary key,
  usuario text,
  accion text not null,
  descripcion text,
  entidad text,
  detalle text,
  ip text,
  fecha timestamptz not null default now(),
  created_at timestamptz not null default now(),
  is_deleted boolean not null default false,
  deleted_at timestamptz
);

alter table public.auditoria add column if not exists usuario text;
alter table public.auditoria add column if not exists accion text;
alter table public.auditoria add column if not exists descripcion text;
alter table public.auditoria add column if not exists entidad text;
alter table public.auditoria add column if not exists detalle text;
alter table public.auditoria add column if not exists ip text;
alter table public.auditoria add column if not exists fecha timestamptz default now();
alter table public.auditoria add column if not exists created_at timestamptz default now();
alter table public.auditoria add column if not exists is_deleted boolean not null default false;
alter table public.auditoria add column if not exists deleted_at timestamptz;

create index if not exists idx_auditoria_fecha on public.auditoria (fecha desc);

-- ============================================================================
-- 7. FUNCIONES AUXILIARES DE SEGURIDAD
--    security definer + search_path fijo para evitar recursión de RLS.
-- ============================================================================
create or replace function public.sigas_es_admin()
returns boolean
language sql
stable
security definer
set search_path = public, auth
as $$
  select exists (
    select 1
    from public.familias f
    where f.auth_id = auth.uid()
      and f.id_cargo = 1
      and f.activo = true
      and f.is_deleted = false
  );
$$;

create or replace function public.sigas_es_jefe_calle()
returns boolean
language sql
stable
security definer
set search_path = public, auth
as $$
  select exists (
    select 1
    from public.jefe_de_calle j
    where j.auth_id = auth.uid()
      and j.activo = true
      and j.is_deleted = false
  );
$$;

create or replace function public.sigas_calle_usuario()
returns integer
language sql
stable
security definer
set search_path = public, auth
as $$
  select coalesce(
    (
      select f.id_calle
      from public.familias f
      where f.auth_id = auth.uid()
        and f.is_deleted = false
        and f.id_calle is not null
      order by f.id
      limit 1
    ),
    (
      select j.id_calle
      from public.jefe_de_calle j
      where j.auth_id = auth.uid()
        and j.activo = true
        and j.is_deleted = false
        and j.id_calle is not null
      order by j.id_jefe_calle
      limit 1
    ),
    (
      select c.id_calle
      from public.calles c
      join public.jefe_de_calle j on j.id_jefe_calle = c.id_jefe_calle
      where j.auth_id = auth.uid()
        and j.activo = true
        and j.is_deleted = false
      order by c.id_calle
      limit 1
    )
  );
$$;

create or replace function public.sigas_puede_gestionar_calle(p_id_calle integer)
returns boolean
language sql
stable
security definer
set search_path = public, auth
as $$
  select
    public.sigas_es_admin()
    or exists (
      select 1
      from public.jefe_de_calle j
      where j.auth_id = auth.uid()
        and j.activo = true
        and j.is_deleted = false
        and j.id_calle = p_id_calle
    )
    or exists (
      select 1
      from public.calles c
      join public.jefe_de_calle j on j.id_jefe_calle = c.id_jefe_calle
      where c.id_calle = p_id_calle
        and j.auth_id = auth.uid()
        and j.activo = true
        and j.is_deleted = false
    );
$$;

create or replace function public.sigas_es_dueno_familia(p_id_familia integer)
returns boolean
language sql
stable
security definer
set search_path = public, auth
as $$
  select exists (
    select 1
    from public.familias f
    where f.id = p_id_familia
      and f.auth_id = auth.uid()
      and f.is_deleted = false
  );
$$;

create or replace function public.sigas_puede_ver_familia(p_id_familia integer)
returns boolean
language sql
stable
security definer
set search_path = public, auth
as $$
  select
    public.sigas_es_admin()
    or public.sigas_es_dueno_familia(p_id_familia)
    or exists (
      select 1
      from public.familias f
      where f.id = p_id_familia
        and public.sigas_puede_gestionar_calle(f.id_calle)
    );
$$;

create or replace function public.sigas_puede_gestionar_familia(p_id_familia integer)
returns boolean
language sql
stable
security definer
set search_path = public, auth
as $$
  select
    public.sigas_es_admin()
    or exists (
      select 1
      from public.familias f
      where f.id = p_id_familia
        and public.sigas_puede_gestionar_calle(f.id_calle)
    );
$$;

create or replace function public.sigas_puede_ver_pedido(p_id_pedido integer)
returns boolean
language sql
stable
security definer
set search_path = public, auth
as $$
  select
    public.sigas_es_admin()
    or exists (
      select 1
      from public.pedidos p
      join public.familias f on f.id = p.id_familias
      where p.id_pedido = p_id_pedido
        and (
          f.auth_id = auth.uid()
          or public.sigas_puede_gestionar_calle(f.id_calle)
        )
    );
$$;

create or replace function public.sigas_puede_gestionar_pedido(p_id_pedido integer)
returns boolean
language sql
stable
security definer
set search_path = public, auth
as $$
  select
    public.sigas_es_admin()
    or exists (
      select 1
      from public.pedidos p
      join public.familias f on f.id = p.id_familias
      where p.id_pedido = p_id_pedido
        and public.sigas_puede_gestionar_calle(f.id_calle)
    );
$$;

create or replace function public.sigas_es_jefe_de_familia(p_id_familia integer)
returns boolean
language sql
stable
security definer
set search_path = public, auth
as $$
  select exists (
    select 1
    from public.jefes_familia jf
    where jf.id_familia = p_id_familia
      and jf.auth_id = auth.uid()
      and jf.activo = true
      and jf.is_deleted = false
  );
$$;

-- ============================================================================
-- 8. FUNCIONES INTERNAS
-- ============================================================================
create or replace function public.sigas_registrar_auditoria(
  p_accion text,
  p_descripcion text,
  p_entidad text default null,
  p_detalle text default null
)
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_usuario text;
begin
  v_usuario := coalesce(
    auth.jwt() ->> 'email',
    auth.uid()::text,
    'sistema'
  );

  insert into public.auditoria (usuario, accion, descripcion, entidad, detalle, fecha)
  values (v_usuario, p_accion, p_descripcion, p_entidad, p_detalle, now());
end;
$$;

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

create or replace function public.sigas_set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

-- Mantiene sincronizada la calle del Jefe de Familia con la de su familia.
create or replace function public.sigas_validar_jefe_familia()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_calle integer;
begin
  select f.id_calle into v_calle
  from public.familias f
  where f.id = new.id_familia;

  if v_calle is null then
    raise exception 'La familia no tiene una calle asignada.'
      using errcode = '23514';
  end if;

  if new.id_calle is null then
    new.id_calle := v_calle;
  end if;

  if new.id_calle is distinct from v_calle then
    raise exception 'La calle del Jefe de Familia debe coincidir con la calle de la familia.'
      using errcode = '23514';
  end if;

  return new;
end;
$$;

-- Evita que un Jefe de Calle modifique campos sensibles de una familia
-- (rol, cuenta de acceso, calle o borrado lógico). Esas acciones son solo del admin.
create or replace function public.sigas_proteger_campos_familia()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  if public.sigas_es_admin() then
    return new;
  end if;

  if new.id is distinct from old.id
     or new.auth_id is distinct from old.auth_id
     or new.id_cargo is distinct from old.id_cargo
     or new.id_calle is distinct from old.id_calle
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

-- ============================================================================
-- 9. TRIGGERS
-- ============================================================================
drop trigger if exists trg_familias_updated_at on public.familias;
create trigger trg_familias_updated_at
before update on public.familias
for each row execute function public.sigas_set_updated_at();

drop trigger if exists trg_familias_proteger_campos on public.familias;
create trigger trg_familias_proteger_campos
before update on public.familias
for each row execute function public.sigas_proteger_campos_familia();

drop trigger if exists trg_jefe_de_calle_updated_at on public.jefe_de_calle;
create trigger trg_jefe_de_calle_updated_at
before update on public.jefe_de_calle
for each row execute function public.sigas_set_updated_at();

drop trigger if exists trg_calles_updated_at on public.calles;
create trigger trg_calles_updated_at
before update on public.calles
for each row execute function public.sigas_set_updated_at();

drop trigger if exists trg_pedidos_updated_at on public.pedidos;
create trigger trg_pedidos_updated_at
before update on public.pedidos
for each row execute function public.sigas_set_updated_at();

drop trigger if exists trg_ciclos_updated_at on public.ciclos_distribucion;
create trigger trg_ciclos_updated_at
before update on public.ciclos_distribucion
for each row execute function public.sigas_set_updated_at();

drop trigger if exists trg_jefes_familia_updated_at on public.jefes_familia;
create trigger trg_jefes_familia_updated_at
before update on public.jefes_familia
for each row execute function public.sigas_set_updated_at();

drop trigger if exists trg_jefes_familia_validar on public.jefes_familia;
create trigger trg_jefes_familia_validar
before insert or update on public.jefes_familia
for each row execute function public.sigas_validar_jefe_familia();

drop trigger if exists trg_bombonas_updated_at on public.bombonas;
create trigger trg_bombonas_updated_at
before update on public.bombonas
for each row execute function public.sigas_set_updated_at();

-- ============================================================================
-- 10. RPC · REGISTRO PÚBLICO DE FAMILIA (queda PENDIENTE)
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
begin
  if p_auth_id is null then
    raise exception 'La cuenta de acceso es obligatoria.' using errcode = '22023';
  end if;

  if coalesce(trim(p_nombre), '') = '' then
    raise exception 'El nombre de la familia es obligatorio.' using errcode = '22023';
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
    trim(p_nombre),
    p_id_calle,
    3,
    false,
    'pendiente',
    nullif(trim(p_telefono), ''),
    nullif(trim(p_direccion), ''),
    p_personas,
    nullif(trim(p_email), ''),
    false
  );

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
        'La familia %s (cédula %s) solicitó registro en tu calle.',
        trim(p_nombre),
        p_id
      ),
      jsonb_build_object(
        'id_familia', p_id,
        'id_calle', p_id_calle,
        'email', p_email
      )
    );
    v_notificado := true;
  end if;

  perform public.sigas_registrar_auditoria(
    'registro',
    'Nuevo registro de familia pendiente de aprobación',
    'familia',
    format('Familia %s · cédula %s', trim(p_nombre), p_id)
  );

  return jsonb_build_object(
    'ok', true,
    'id_familia', p_id,
    'notificado', v_notificado
  );
exception
  when unique_violation then
    raise exception 'Ya existe un registro con esa cédula. Contacta al Jefe de Calle.'
      using errcode = '23505';
end;
$$;

-- ============================================================================
-- 11. RPC · APROBAR REGISTRO DE FAMILIA
-- ============================================================================
create or replace function public.aprobar_registro_familia(p_id_familia integer)
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_familia public.familias%rowtype;
  v_jefe_activo public.jefes_familia%rowtype;
  v_nuevo_jefe public.jefes_familia%rowtype;
begin
  if not public.sigas_puede_gestionar_familia(p_id_familia) then
    raise exception 'No tienes permiso para aprobar este registro.' using errcode = '42501';
  end if;

  select * into v_familia
  from public.familias
  where id = p_id_familia and is_deleted = false
  for update;

  if not found then
    raise exception 'El registro ya no existe o fue eliminado.' using errcode = 'P0002';
  end if;

  select * into v_jefe_activo
  from public.jefes_familia
  where id_familia = p_id_familia
    and activo = true
    and is_deleted = false
  limit 1;

  if found then
    raise exception 'La familia ya tiene un Jefe de Familia activo (%). Debes darlo de baja antes de asignar otro.',
      coalesce(v_jefe_activo.nombre, 'ID ' || v_jefe_activo.id_jefe_familia)
      using errcode = '23505';
  end if;

  begin
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
    returning * into v_nuevo_jefe;
  exception
    when unique_violation then
      raise exception 'La familia ya tiene un Jefe de Familia activo. Debes darlo de baja antes de asignar otro.'
        using errcode = '23505';
  end;

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
    jsonb_build_object('id_familia', v_familia.id)
  );

  perform public.sigas_registrar_auditoria(
    'aprobar',
    'Registro de familia aprobado',
    'familia',
    format('Familia %s · cédula %s', v_familia.nombre_familia, v_familia.id)
  );

  return jsonb_build_object(
    'ok', true,
    'id_familia', v_familia.id,
    'id_jefe_familia', v_nuevo_jefe.id_jefe_familia
  );
end;
$$;

-- ============================================================================
-- 12. RPC · RECHAZAR REGISTRO DE FAMILIA
-- ============================================================================
create or replace function public.rechazar_registro_familia(
  p_id_familia integer,
  p_motivo text
)
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_familia public.familias%rowtype;
  v_motivo text;
begin
  if not public.sigas_puede_gestionar_familia(p_id_familia) then
    raise exception 'No tienes permiso para rechazar este registro.' using errcode = '42501';
  end if;

  v_motivo := nullif(trim(p_motivo), '');
  if v_motivo is null then
    raise exception 'Indica el motivo del rechazo.' using errcode = '22023';
  end if;

  select * into v_familia
  from public.familias
  where id = p_id_familia and is_deleted = false
  for update;

  if not found then
    raise exception 'El registro ya no existe o fue eliminado.' using errcode = 'P0002';
  end if;

  if exists (
    select 1 from public.jefes_familia
    where id_familia = p_id_familia
      and activo = true
      and is_deleted = false
  ) then
    raise exception 'No puedes rechazar una familia que tiene un Jefe de Familia activo. Dale de baja primero.'
      using errcode = '23505';
  end if;

  update public.familias
  set estado = 'rechazado',
      activo = false,
      notas_rechazo = v_motivo,
      updated_at = now()
  where id = p_id_familia;

  perform public.sigas_notificar(
    v_familia.auth_id,
    null,
    v_familia.id,
    'registro_rechazado',
    'Registro rechazado',
    format('Tu registro fue rechazado. Motivo: %s', v_motivo),
    jsonb_build_object('id_familia', v_familia.id, 'motivo', v_motivo)
  );

  perform public.sigas_registrar_auditoria(
    'rechazar',
    'Registro de familia rechazado',
    'familia',
    format('Familia %s · cédula %s · motivo: %s', v_familia.nombre_familia, v_familia.id, v_motivo)
  );

  return jsonb_build_object('ok', true, 'id_familia', v_familia.id);
end;
$$;

-- ============================================================================
-- 13. RPC · ACTUALIZAR REGISTRO DE FAMILIA
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
begin
  if not public.sigas_puede_gestionar_familia(p_id_familia) then
    raise exception 'No tienes permiso para modificar este registro.' using errcode = '42501';
  end if;

  v_nombre := nullif(trim(p_nombre), '');
  if v_nombre is null then
    raise exception 'El nombre es obligatorio.' using errcode = '22023';
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
      telefono = nullif(trim(p_telefono), ''),
      direccion = nullif(trim(p_direccion), ''),
      num_personas = p_personas,
      id_calle = coalesce(p_id_calle, id_calle),
      updated_at = now()
  where id = p_id_familia;

  update public.jefes_familia
  set nombre = v_nombre,
      telefono = nullif(trim(p_telefono), ''),
      id_calle = coalesce(p_id_calle, id_calle),
      updated_at = now()
  where id_familia = p_id_familia
    and activo = true
    and is_deleted = false;

  perform public.sigas_registrar_auditoria(
    'modificar',
    'Registro de familia modificado',
    'familia',
    format('Familia %s · cédula %s', v_nombre, p_id_familia)
  );

  return jsonb_build_object('ok', true, 'id_familia', p_id_familia);
end;
$$;

-- ============================================================================
-- 14. RPC · DAR DE BAJA AL JEFE DE FAMILIA (soft delete)
-- ============================================================================
create or replace function public.dar_baja_jefe_familia(p_id_jefe_familia bigint)
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_jefe public.jefes_familia%rowtype;
begin
  select * into v_jefe
  from public.jefes_familia
  where id_jefe_familia = p_id_jefe_familia and is_deleted = false
  for update;

  if not found then
    raise exception 'El Jefe de Familia ya no existe o fue dado de baja.' using errcode = 'P0002';
  end if;

  if not public.sigas_puede_gestionar_calle(v_jefe.id_calle) then
    raise exception 'No tienes permiso para dar de baja a este Jefe de Familia.' using errcode = '42501';
  end if;

  update public.jefes_familia
  set activo = false,
      is_deleted = true,
      deleted_at = now(),
      updated_at = now()
  where id_jefe_familia = p_id_jefe_familia;

  perform public.sigas_notificar(
    v_jefe.auth_id,
    null,
    v_jefe.id_familia,
    'jefe_familia_baja',
    'Jefe de Familia dado de baja',
    'Tu rol como Jefe de Familia fue dado de baja. La familia podrá asignar un nuevo Jefe de Familia.',
    jsonb_build_object('id_familia', v_jefe.id_familia, 'id_jefe_familia', p_id_jefe_familia)
  );

  perform public.sigas_registrar_auditoria(
    'baja',
    'Jefe de Familia dado de baja',
    'jefe_familia',
    format('%s · familia %s', v_jefe.nombre, v_jefe.id_familia)
  );

  return jsonb_build_object('ok', true, 'id_jefe_familia', p_id_jefe_familia);
end;
$$;

-- ============================================================================
-- 15. RPC · ELIMINAR USUARIO LÓGICAMENTE (soft delete)
--     La reautenticación con la contraseña del admin se hace en el cliente.
-- ============================================================================
create or replace function public.eliminar_usuario_logico(
  p_id integer,
  p_auth_id uuid default null,
  p_motivo text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_familia public.familias%rowtype;
  v_auth_id uuid;
  v_familias integer := 0;
  v_jefes_familia integer := 0;
  v_jefes_calle integer := 0;
begin
  if not public.sigas_es_admin() then
    raise exception 'No tienes permiso para eliminar usuarios.' using errcode = '42501';
  end if;

  select * into v_familia
  from public.familias
  where id = p_id
  for update;

  v_auth_id := coalesce(p_auth_id, v_familia.auth_id);

  if v_auth_id is not null and v_auth_id = auth.uid() then
    raise exception 'No puedes eliminar tu propia cuenta.' using errcode = '42501';
  end if;

  update public.familias
  set is_deleted = true,
      deleted_at = now(),
      activo = false,
      updated_at = now()
  where id = p_id
     or (v_auth_id is not null and auth_id = v_auth_id);
  get diagnostics v_familias = row_count;

  update public.jefes_familia
  set activo = false,
      is_deleted = true,
      deleted_at = now(),
      updated_at = now()
  where is_deleted = false
    and (
      id_familia = p_id
      or (v_auth_id is not null and auth_id = v_auth_id)
    );
  get diagnostics v_jefes_familia = row_count;

  if v_auth_id is not null then
    update public.calles c
    set id_jefe_calle = null
    from public.jefe_de_calle j
    where c.id_jefe_calle = j.id_jefe_calle
      and j.auth_id = v_auth_id;

    update public.jefe_de_calle
    set activo = false,
        is_deleted = true,
        deleted_at = now(),
        updated_at = now()
    where is_deleted = false
      and auth_id = v_auth_id;
    get diagnostics v_jefes_calle = row_count;
  end if;

  perform public.sigas_registrar_auditoria(
    'eliminar',
    'Usuario eliminado lógicamente',
    'usuario',
    format(
      'ID %s · auth %s · motivo: %s',
      p_id,
      coalesce(v_auth_id::text, 'sin auth'),
      coalesce(nullif(trim(p_motivo), ''), 'no indicado')
    )
  );

  return jsonb_build_object(
    'ok', true,
    'familias', v_familias,
    'jefes_familia', v_jefes_familia,
    'jefes_calle', v_jefes_calle
  );
end;
$$;

-- ============================================================================
-- 16. RLS · LIMPIAR POLÍTICAS ANTERIORES Y CREAR LAS NUEVAS
-- ============================================================================
do $$
declare
  r record;
begin
  for r in
    select schemaname, tablename, policyname
    from pg_policies
    where schemaname = 'public'
      and tablename = any (array[
        'familias',
        'jefe_de_calle',
        'calles',
        'cargos',
        'pedidos',
        'ciclos_distribucion',
        'historial_distribucion',
        'jefes_familia',
        'notificaciones',
        'bombonas',
        'auditoria'
      ])
  loop
    execute format('drop policy if exists %I on %I.%I', r.policyname, r.schemaname, r.tablename);
  end loop;
end $$;

alter table public.familias enable row level security;
alter table public.jefe_de_calle enable row level security;
alter table public.calles enable row level security;
alter table public.cargos enable row level security;
alter table public.pedidos enable row level security;
alter table public.ciclos_distribucion enable row level security;
alter table public.historial_distribucion enable row level security;
alter table public.jefes_familia enable row level security;
alter table public.notificaciones enable row level security;
alter table public.bombonas enable row level security;
alter table public.auditoria enable row level security;

-- ---------------------------------------------------------------------------
-- calles (catálogo público de lectura; escritura solo admin)
-- ---------------------------------------------------------------------------
create policy "calles_select_publico"
  on public.calles for select
  to anon, authenticated
  using (true);

create policy "calles_insert_admin"
  on public.calles for insert
  to authenticated
  with check (public.sigas_es_admin());

create policy "calles_update_admin"
  on public.calles for update
  to authenticated
  using (public.sigas_es_admin())
  with check (public.sigas_es_admin());

create policy "calles_delete_admin"
  on public.calles for delete
  to authenticated
  using (public.sigas_es_admin());

-- ---------------------------------------------------------------------------
-- cargos (catálogo público de lectura; escritura solo admin)
-- ---------------------------------------------------------------------------
create policy "cargos_select_publico"
  on public.cargos for select
  to anon, authenticated
  using (true);

create policy "cargos_insert_admin"
  on public.cargos for insert
  to authenticated
  with check (public.sigas_es_admin());

create policy "cargos_update_admin"
  on public.cargos for update
  to authenticated
  using (public.sigas_es_admin())
  with check (public.sigas_es_admin());

create policy "cargos_delete_admin"
  on public.cargos for delete
  to authenticated
  using (public.sigas_es_admin());

-- ---------------------------------------------------------------------------
-- familias
-- ---------------------------------------------------------------------------
create policy "familias_select"
  on public.familias for select
  to authenticated
  using (
    public.sigas_es_admin()
    or auth_id = auth.uid()
    or public.sigas_puede_gestionar_calle(id_calle)
  );

create policy "familias_insert"
  on public.familias for insert
  to authenticated
  with check (
    public.sigas_es_admin()
    or (
      auth_id = auth.uid()
      and id_cargo = 3
      and estado = 'pendiente'
      and activo = false
      and is_deleted = false
    )
  );

create policy "familias_update"
  on public.familias for update
  to authenticated
  using (
    public.sigas_es_admin()
    or public.sigas_puede_gestionar_calle(id_calle)
  )
  with check (
    public.sigas_es_admin()
    or public.sigas_puede_gestionar_calle(id_calle)
  );

-- No se crea política DELETE: el borrado es lógico (is_deleted = true).

-- ---------------------------------------------------------------------------
-- jefe_de_calle
-- ---------------------------------------------------------------------------
create policy "jefe_de_calle_select"
  on public.jefe_de_calle for select
  to authenticated
  using (
    public.sigas_es_admin()
    or auth_id = auth.uid()
  );

create policy "jefe_de_calle_insert_admin"
  on public.jefe_de_calle for insert
  to authenticated
  with check (public.sigas_es_admin());

create policy "jefe_de_calle_update_admin"
  on public.jefe_de_calle for update
  to authenticated
  using (public.sigas_es_admin())
  with check (public.sigas_es_admin());

create policy "jefe_de_calle_delete_admin"
  on public.jefe_de_calle for delete
  to authenticated
  using (public.sigas_es_admin());

-- ---------------------------------------------------------------------------
-- pedidos
-- ---------------------------------------------------------------------------
create policy "pedidos_select"
  on public.pedidos for select
  to authenticated
  using (public.sigas_puede_ver_pedido(id_pedido));

create policy "pedidos_insert"
  on public.pedidos for insert
  to authenticated
  with check (
    public.sigas_puede_gestionar_familia(id_familias)
    or public.sigas_es_dueno_familia(id_familias)
  );

create policy "pedidos_update"
  on public.pedidos for update
  to authenticated
  using (public.sigas_puede_gestionar_pedido(id_pedido))
  with check (public.sigas_puede_gestionar_pedido(id_pedido));

create policy "pedidos_delete_admin"
  on public.pedidos for delete
  to authenticated
  using (public.sigas_es_admin());

-- ---------------------------------------------------------------------------
-- ciclos_distribucion (lectura pública; escritura solo admin)
-- ---------------------------------------------------------------------------
create policy "ciclos_select_publico"
  on public.ciclos_distribucion for select
  to anon, authenticated
  using (true);

create policy "ciclos_insert_admin"
  on public.ciclos_distribucion for insert
  to authenticated
  with check (public.sigas_es_admin());

create policy "ciclos_update_admin"
  on public.ciclos_distribucion for update
  to authenticated
  using (public.sigas_es_admin())
  with check (public.sigas_es_admin());

create policy "ciclos_delete_admin"
  on public.ciclos_distribucion for delete
  to authenticated
  using (public.sigas_es_admin());

-- ---------------------------------------------------------------------------
-- historial_distribucion
-- ---------------------------------------------------------------------------
create policy "historial_select"
  on public.historial_distribucion for select
  to authenticated
  using (public.sigas_puede_ver_pedido(id_pedido));

create policy "historial_insert"
  on public.historial_distribucion for insert
  to authenticated
  with check (public.sigas_puede_gestionar_pedido(id_pedido));

create policy "historial_update_admin"
  on public.historial_distribucion for update
  to authenticated
  using (public.sigas_es_admin())
  with check (public.sigas_es_admin());

create policy "historial_delete_admin"
  on public.historial_distribucion for delete
  to authenticated
  using (public.sigas_es_admin());

-- ---------------------------------------------------------------------------
-- jefes_familia
-- ---------------------------------------------------------------------------
create policy "jefes_familia_select"
  on public.jefes_familia for select
  to authenticated
  using (
    public.sigas_es_admin()
    or auth_id = auth.uid()
    or public.sigas_puede_gestionar_calle(id_calle)
  );

create policy "jefes_familia_insert"
  on public.jefes_familia for insert
  to authenticated
  with check (
    public.sigas_es_admin()
    or public.sigas_puede_gestionar_calle(id_calle)
  );

create policy "jefes_familia_update"
  on public.jefes_familia for update
  to authenticated
  using (
    public.sigas_es_admin()
    or public.sigas_puede_gestionar_calle(id_calle)
  )
  with check (
    public.sigas_es_admin()
    or public.sigas_puede_gestionar_calle(id_calle)
  );

-- No se crea política DELETE: el borrado es lógico.

-- ---------------------------------------------------------------------------
-- notificaciones
-- ---------------------------------------------------------------------------
create policy "notificaciones_select"
  on public.notificaciones for select
  to authenticated
  using (
    destinatario_auth_id = auth.uid()
    or public.sigas_es_admin()
  );

create policy "notificaciones_insert"
  on public.notificaciones for insert
  to authenticated
  with check (
    public.sigas_es_admin()
    or destinatario_auth_id = auth.uid()
    or (
      public.sigas_es_jefe_calle()
      and id_familia is not null
      and public.sigas_puede_gestionar_familia(id_familia)
    )
  );

create policy "notificaciones_update"
  on public.notificaciones for update
  to authenticated
  using (
    destinatario_auth_id = auth.uid()
    or public.sigas_es_admin()
  )
  with check (
    destinatario_auth_id = auth.uid()
    or public.sigas_es_admin()
  );

-- No se crea política DELETE: se marca is_deleted = true.

-- ---------------------------------------------------------------------------
-- bombonas
-- ---------------------------------------------------------------------------
create policy "bombonas_select"
  on public.bombonas for select
  to authenticated
  using (
    public.sigas_es_admin()
    or public.sigas_puede_gestionar_calle(id_calle)
  );

create policy "bombonas_insert_admin"
  on public.bombonas for insert
  to authenticated
  with check (public.sigas_es_admin());

create policy "bombonas_update_admin"
  on public.bombonas for update
  to authenticated
  using (public.sigas_es_admin())
  with check (public.sigas_es_admin());

-- No se crea política DELETE: el borrado es lógico.

-- ---------------------------------------------------------------------------
-- auditoria
-- ---------------------------------------------------------------------------
create policy "auditoria_select_admin"
  on public.auditoria for select
  to authenticated
  using (public.sigas_es_admin());

create policy "auditoria_insert"
  on public.auditoria for insert
  to authenticated
  with check (true);

create policy "auditoria_update_admin"
  on public.auditoria for update
  to authenticated
  using (public.sigas_es_admin())
  with check (public.sigas_es_admin());

create policy "auditoria_delete_admin"
  on public.auditoria for delete
  to authenticated
  using (public.sigas_es_admin());

-- ============================================================================
-- 17. GRANTS
-- ============================================================================
grant usage on schema public to anon, authenticated;

grant select on public.calles, public.cargos, public.ciclos_distribucion
  to anon, authenticated;

grant select, insert, update, delete on public.calles to authenticated;
grant select, insert, update, delete on public.cargos to authenticated;
grant select, insert, update, delete on public.ciclos_distribucion to authenticated;

grant select, insert, update, delete on public.familias to authenticated;
grant select, insert, update, delete on public.jefe_de_calle to authenticated;
grant select, insert, update, delete on public.pedidos to authenticated;
grant select, insert, update, delete on public.historial_distribucion to authenticated;
grant select, insert, update, delete on public.jefes_familia to authenticated;
grant select, insert, update, delete on public.notificaciones to authenticated;
grant select, insert, update, delete on public.bombonas to authenticated;
grant select, insert, update, delete on public.auditoria to authenticated;

grant usage, select on all sequences in schema public to authenticated;

grant execute on function public.sigas_es_admin() to anon, authenticated;
grant execute on function public.sigas_es_jefe_calle() to anon, authenticated;
grant execute on function public.sigas_calle_usuario() to anon, authenticated;
grant execute on function public.sigas_puede_gestionar_calle(integer) to anon, authenticated;
grant execute on function public.sigas_es_dueno_familia(integer) to anon, authenticated;
grant execute on function public.sigas_puede_ver_familia(integer) to anon, authenticated;
grant execute on function public.sigas_puede_gestionar_familia(integer) to anon, authenticated;
grant execute on function public.sigas_puede_ver_pedido(integer) to anon, authenticated;
grant execute on function public.sigas_puede_gestionar_pedido(integer) to anon, authenticated;
grant execute on function public.sigas_es_jefe_de_familia(integer) to anon, authenticated;

grant execute on function public.registrar_familia_pendiente(integer, uuid, text, integer, text, text, integer, text)
  to anon, authenticated;
grant execute on function public.aprobar_registro_familia(integer) to authenticated;
grant execute on function public.rechazar_registro_familia(integer, text) to authenticated;
grant execute on function public.actualizar_registro_familia(integer, text, text, text, integer, integer) to authenticated;
grant execute on function public.dar_baja_jefe_familia(bigint) to authenticated;
grant execute on function public.eliminar_usuario_logico(integer, uuid, text) to authenticated;

revoke all on function public.sigas_registrar_auditoria(text, text, text, text) from public;
revoke all on function public.sigas_notificar(uuid, integer, integer, text, text, text, jsonb) from public;
revoke all on function public.sigas_set_updated_at() from public;
revoke all on function public.sigas_validar_jefe_familia() from public;
revoke all on function public.sigas_proteger_campos_familia() from public;

-- ============================================================================
-- 18. SUPABASE REALTIME PARA NOTIFICACIONES
-- ============================================================================
alter table public.notificaciones replica identity full;

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'notificaciones'
  ) then
    alter publication supabase_realtime add table public.notificaciones;
  end if;
end $$;

commit;
