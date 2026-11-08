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
