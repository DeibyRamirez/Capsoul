-- Capsoul · Amistad aceptada, cápsula compartida e invitación (000009).
\set ON_ERROR_STOP 1

insert into auth.users (id, email, raw_user_meta_data, email_confirmed_at) values
  ('00000000-0000-0000-0000-00000000020a', 'share-a@x.co', '{"nombre_visible":"ShareA"}', now()),
  ('00000000-0000-0000-0000-00000000020b', 'share-b@x.co', '{"nombre_visible":"ShareB"}', now()),
  ('00000000-0000-0000-0000-00000000020c', 'share-c@x.co', '{"nombre_visible":"ShareC"}', now())
on conflict do nothing;

insert into public.amistades (solicitante_id, receptor_id, estado, respondido_en)
values (
  '00000000-0000-0000-0000-00000000020a',
  '00000000-0000-0000-0000-00000000020b',
  'aceptada',
  now()
)
on conflict do nothing;

set role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-00000000020a', false);

do $$
declare n integer;
begin
  select count(*) into n from public.mis_amigos();
  if n < 1 then
    raise exception 'FALLO: A no ve a su amigo aceptado';
  end if;
end $$;

insert into public.elementos (
  id, propietario_id, tipo, cloudinary_public_id, cloudinary_tipo_recurso, bytes, ancho, alto
) values (
  '12000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-00000000020a',
  'foto', 'capsoul/share/1', 'image', 1000, 1600, 1200
);

insert into public.capsulas (id, autor_id, titulo, mensaje, fecha_apertura, estado)
values (
  '22000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-00000000020a',
  'Para B',
  'hola',
  now() + interval '1 day',
  'programada'
);

insert into public.capsula_elementos values (
  '22000000-0000-0000-0000-000000000001',
  '12000000-0000-0000-0000-000000000001',
  0
);

insert into public.capsula_destinatarios (capsula_id, usuario_id)
values (
  '22000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-00000000020b'
);

select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-00000000020b', false);

do $$
declare n integer;
begin
  select count(*) into n from public.capsulas_recibidas();
  if n <> 1 then
    raise exception 'FALLO: B debería ver 1 cápsula, vio %', n;
  end if;
end $$;

select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-00000000020a', false);
select public.crear_invitacion_amistad(7) as token_invite \gset

select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-00000000020c', false);
select public.aceptar_invitacion_amistad(:'token_invite');

do $$
declare n integer;
begin
  select count(*) into n from public.mis_amigos();
  if n < 1 then
    raise exception 'FALLO: C no quedó amigo de A';
  end if;
end $$;

reset role;
select 'OK amistad compartir' as r;
