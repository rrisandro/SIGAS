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
