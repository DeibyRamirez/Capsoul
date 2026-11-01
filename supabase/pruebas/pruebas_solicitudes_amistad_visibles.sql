-- Capsoul · El receptor ve la solicitud aunque el solicitante tenga perfil privado.
\set ON_ERROR_STOP 1

insert into auth.users (id, email, raw_user_meta_data, email_confirmed_at) values
  ('98100000-0000-0000-0000-0000000000a1', 'solicita-privada@capsoul.app', '{"nombre_visible":"Ana Privada"}', now()),
  ('98100000-0000-0000-0000-0000000000b1', 'recibe-privada@capsoul.app', '{"nombre_visible":"Beto Receptor"}', now()),
  ('98100000-0000-0000-0000-0000000000c1', 'ajena-privada@capsoul.app', '{"nombre_visible":"Caro Ajena"}', now())
on conflict do nothing;

do $$
declare firma text;
begin
  if exists (
    select 1
      from pg_proc p
      join pg_namespace n on n.oid = p.pronamespace
     where n.nspname = 'public'
       and p.proname = 'mis_solicitudes_amistad_pendientes'
       and pg_get_function_result(p.oid) ilike '%correo%'
  ) then
    raise exception 'FALLO: mis_solicitudes_amistad_pendientes expone correo';
  end if;

  select pg_get_function_identity_arguments(p.oid)
    into firma
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public'
     and p.proname = 'mis_solicitudes_amistad_pendientes';
  if firma is distinct from '' then
    raise exception 'FALLO: la firma de la función cambió (%)', firma;
  end if;
end $$;

update public.usuarios
   set perfil_publico = false
 where id in (
   '98100000-0000-0000-0000-0000000000a1',
   '98100000-0000-0000-0000-0000000000b1',
   '98100000-0000-0000-0000-0000000000c1'
 );

set role authenticated;
select set_config('request.jwt.claim.sub', '98100000-0000-0000-0000-0000000000a1', false);
select public.enviar_solicitud_amistad('98100000-0000-0000-0000-0000000000b1');

select set_config('request.jwt.claim.sub', '98100000-0000-0000-0000-0000000000b1', false);

do $$
declare
  n_vista integer;
  n_lista integer;
  nombre text;
begin
  select count(*) into n_vista
    from public.perfiles_visibles
   where id = '98100000-0000-0000-0000-0000000000a1';
  if n_vista <> 0 then
    raise exception 'FALLO: el perfil privado del solicitante no debía verse en perfiles_visibles';
  end if;

  select count(*), max(solicitante_nombre)
    into n_lista, nombre
    from public.mis_solicitudes_amistad_pendientes();
  if n_lista <> 1 or nombre is distinct from 'Ana Privada' then
    raise exception 'FALLO: el receptor no ve la solicitud privada (%, %)', n_lista, nombre;
  end if;
end $$;

select set_config('request.jwt.claim.sub', '98100000-0000-0000-0000-0000000000c1', false);

do $$
declare n integer;
begin
  select count(*) into n from public.mis_solicitudes_amistad_pendientes();
  if n <> 0 then
    raise exception 'FALLO: un tercero ve solicitudes ajenas (%)', n;
  end if;
end $$;

select set_config('request.jwt.claim.sub', '98100000-0000-0000-0000-0000000000b1', false);
update public.amistades
   set estado = 'rechazada'
 where solicitante_id = '98100000-0000-0000-0000-0000000000a1'
   and receptor_id = '98100000-0000-0000-0000-0000000000b1';

do $$
declare n integer;
begin
  select count(*) into n from public.mis_solicitudes_amistad_pendientes();
  if n <> 0 then
    raise exception 'FALLO: la solicitud rechazada sigue en la lista (%)', n;
  end if;
end $$;

reset role;

select 'pruebas_solicitudes_amistad_visibles OK';
