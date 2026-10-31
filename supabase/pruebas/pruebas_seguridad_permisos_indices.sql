-- Capsoul · Permisos, search_path e índices (000019).
\set ON_ERROR_STOP 1

do $$
declare
  t text;
  p text;
begin
  -- a) anon sin nada; authenticated sin TRUNCATE, REFERENCES, TRIGGER ni UPDATE.
  foreach t in array array['public.herencia_capsulas', 'public.herencia_eventos', 'public.herencia_solicitudes_legal'] loop
    foreach p in array array['SELECT', 'INSERT', 'UPDATE', 'DELETE', 'TRUNCATE', 'REFERENCES', 'TRIGGER'] loop
      if has_table_privilege('anon', t, p) then
        raise exception 'FALLO: anon tiene % en %', p, t;
      end if;
    end loop;
    foreach p in array array['UPDATE', 'TRUNCATE', 'REFERENCES', 'TRIGGER'] loop
      if has_table_privilege('authenticated', t, p) then
        raise exception 'FALLO: authenticated tiene % en %', p, t;
      end if;
    end loop;
  end loop;
  if not has_table_privilege('authenticated', 'public.herencia_capsulas', 'SELECT,INSERT,DELETE')
     or not has_table_privilege('authenticated', 'public.herencia_eventos', 'SELECT')
     or not has_table_privilege('authenticated', 'public.herencia_solicitudes_legal', 'SELECT,INSERT') then
    raise exception 'FALLO: authenticated perdió un privilegio que cubre RLS';
  end if;
  if has_table_privilege('authenticated', 'public.herencia_eventos', 'INSERT')
     or has_table_privilege('authenticated', 'public.herencia_solicitudes_legal', 'DELETE') then
    raise exception 'FALLO: authenticated tiene escritura de más en legado';
  end if;

  -- b) RPC de amistades
  if has_function_privilege('anon', 'public.mis_amigos()', 'EXECUTE')
     or has_function_privilege('anon', 'public.mis_solicitudes_amistad_pendientes()', 'EXECUTE') then
    raise exception 'FALLO: anon puede ejecutar las RPC de amistades';
  end if;
  if not has_function_privilege('authenticated', 'public.mis_amigos()', 'EXECUTE')
     or not has_function_privilege('authenticated', 'public.mis_solicitudes_amistad_pendientes()', 'EXECUTE') then
    raise exception 'FALLO: authenticated no puede ejecutar las RPC de amistades';
  end if;
end $$;

-- c) Ninguna SECURITY DEFINER de public o privado queda sin search_path vacío.
do $$
declare
  fallas text;
begin
  select string_agg(n.nspname || '.' || p.proname, ', ') into fallas
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where p.prosecdef
    and n.nspname in ('public', 'privado')
    and p.proname in (
      'cumple_criterio_reto', 'evaluar_retos_globales',
      'trg_evaluar_retos_elementos', 'trg_evaluar_retos_capsulas',
      'trg_evaluar_retos_momentos', 'trg_evaluar_retos_amistades',
      'trg_evaluar_retos_usuarios', 'trg_evaluar_retos_herencias',
      'listar_retos_globales', 'contar_retos_pendientes', 'encolar_borrado_medio')
    and not coalesce(p.proconfig @> array['search_path=""'], false);
  if fallas is not null then
    raise exception 'FALLO: search_path sin fijar en %', fallas;
  end if;
end $$;

-- c) Con search_path vacío los retos siguen evaluándose y listándose.
insert into auth.users (id, email, raw_user_meta_data, email_confirmed_at) values
  ('00000000-0000-0000-0000-0000000019aa', 'permisos@capsoul.app', '{"nombre_visible":"Permisos"}', now())
on conflict do nothing;

set role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-0000000019aa', false);
do $$
declare n integer;
begin
  perform public.establecer_mi_nombre_usuario('permisos_19');
  select count(*) into n from public.listar_retos_globales() where completado;
  if n < 1 then
    raise exception 'FALLO: el reto de nombre de usuario no se completó con search_path vacío';
  end if;
  perform public.contar_retos_pendientes();
end $$;
reset role;

-- d) Índices
do $$
declare
  falta text;
begin
  select string_agg(i, ', ') into falta
  from unnest(array[
    'public.reto_participantes_elemento_idx',
    'public.reto_participantes_capsula_idx',
    'public.usuarios_persona_confianza_legado_idx',
    'public.herencia_eventos_actor_idx',
    'public.herencia_solicitudes_legal_solicitante_idx']) as i
  where to_regclass(i) is null;
  if falta is not null then
    raise exception 'FALLO: faltan índices %', falta;
  end if;
end $$;

select 'OK seguridad permisos indices' as r;
