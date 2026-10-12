\set ON_ERROR_STOP 1
-- Requiere migración 000009. Usuarios A y B de pruebas_rls o nuevos.

insert into auth.users (id, email, raw_user_meta_data, email_confirmed_at) values
 ('00000000-0000-0000-0000-00000000020a','share-a@x.co','{"nombre_visible":"ShareA"}', now()),
 ('00000000-0000-0000-0000-00000000020b','share-b@x.co','{"nombre_visible":"ShareB"}', now())
 on conflict do nothing;

\set role authenticated
\set request.jwt.claim.sub '00000000-0000-0000-0000-00000000020a'

insert into public.amistades (solicitante_id, receptor_id, estado, respondido_en)
values (
  '00000000-0000-0000-0000-00000000020a',
  '00000000-0000-0000-0000-00000000020b',
  'aceptada',
  now()
) on conflict do nothing;

select count(*) as amigos_a from public.mis_amigos();

insert into public.elementos (id, propietario_id, tipo, cloudinary_public_id, cloudinary_tipo_recurso)
values (
  '12000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-00000000020a',
  'foto', 'capsoul/share/1', 'image'
) on conflict do nothing;

insert into public.capsulas (id, autor_id, titulo, mensaje, fecha_apertura, estado)
values (
  '22000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-00000000020a',
  'Para B',
  'hola',
  now() + interval '1 day',
  'programada'
) on conflict do nothing;

insert into public.capsula_elementos values (
  '22000000-0000-0000-0000-000000000001',
  '12000000-0000-0000-0000-000000000001',
  0
) on conflict do nothing;

insert into public.capsula_destinatarios (capsula_id, usuario_id)
values (
  '22000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-00000000020b'
);

\set request.jwt.claim.sub '00000000-0000-0000-0000-00000000020b'
select count(*) as recibidas_b from public.capsulas_recibidas();
select titulo from public.capsulas where id = '22000000-0000-0000-0000-000000000001';

\echo '--- invitación amistad para usuario C'
\set request.jwt.claim.sub '00000000-0000-0000-0000-00000000020a'
select public.crear_invitacion_amistad(7) as token_invite \gset

insert into auth.users (id, email, raw_user_meta_data, email_confirmed_at) values
 ('00000000-0000-0000-0000-00000000020c','share-c@x.co','{"nombre_visible":"ShareC"}', now())
 on conflict do nothing;

\set request.jwt.claim.sub '00000000-0000-0000-0000-00000000020c'
select public.aceptar_invitacion_amistad(:'token_invite');
select count(*) as amigos_c_con_a from public.mis_amigos();

reset role
