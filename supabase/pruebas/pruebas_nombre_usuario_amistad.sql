-- Capsoul · nombre_usuario y solicitud de amistad por id (000010).
\set ON_ERROR_STOP 1

insert into auth.users (id, email, raw_user_meta_data, email_confirmed_at) values
  ('00000000-0000-0000-0000-00000000030a', 'nombre-a@x.co', '{"nombre_visible":"NombreA"}', now()),
  ('00000000-0000-0000-0000-00000000030b', 'nombre-b@x.co', '{"nombre_visible":"NombreB"}', now())
on conflict do nothing;

set role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-00000000030a', false);
select public.establecer_mi_nombre_usuario('nombrea');

select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-00000000030b', false);
select public.establecer_mi_nombre_usuario('nombreb');

do $$
declare encontrado uuid;
begin
  select usuario_id into encontrado
  from public.resolver_usuario_por_arroba('nombrea');
  if encontrado is distinct from '00000000-0000-0000-0000-00000000030a' then
    raise exception 'FALLO: no se resolvió @nombrea';
  end if;
end $$;

select public.enviar_solicitud_amistad('00000000-0000-0000-0000-00000000030a');
reset role;

do $$
begin
  if not exists (
    select 1 from public.amistades
    where solicitante_id = '00000000-0000-0000-0000-00000000030b'
      and receptor_id = '00000000-0000-0000-0000-00000000030a'
      and estado = 'pendiente'
  ) then
    raise exception 'FALLO: no quedó la solicitud pendiente';
  end if;
end $$;

select 'OK nombre_usuario' as r;
