-- Capsoul · Permisos de herencias y cápsulas vinculadas (migración 000025).
-- U1 autor, U2 destinatario original de la cápsula, U3 beneficiario de la herencia.
-- Ejecutar como postgres sobre una base con las migraciones aplicadas.

\set ON_ERROR_STOP 1

insert into auth.users (id, email, raw_user_meta_data, email_confirmed_at) values
 ('a0000000-0000-0000-0000-000000000001','u1@x.co','{"nombre_visible":"Uno"}', now()),
 ('a0000000-0000-0000-0000-000000000002','u2@x.co','{"nombre_visible":"Dos"}', now()),
 ('a0000000-0000-0000-0000-000000000003','u3@x.co','{"nombre_visible":"Tres"}', now())
on conflict (id) do nothing;

-- Amistad U1-U2 y U1-U3 (hace falta para destinatarios y confianza)
set role authenticated;
set request.jwt.claim.sub = 'a0000000-0000-0000-0000-000000000001';
insert into public.amistades (solicitante_id, receptor_id) values
 ('a0000000-0000-0000-0000-000000000001','a0000000-0000-0000-0000-000000000002'),
 ('a0000000-0000-0000-0000-000000000001','a0000000-0000-0000-0000-000000000003');
set request.jwt.claim.sub = 'a0000000-0000-0000-0000-000000000002';
update public.amistades set estado = 'aceptada'
 where solicitante_id = 'a0000000-0000-0000-0000-000000000001'
   and receptor_id = 'a0000000-0000-0000-0000-000000000002';
set request.jwt.claim.sub = 'a0000000-0000-0000-0000-000000000003';
update public.amistades set estado = 'aceptada'
 where solicitante_id = 'a0000000-0000-0000-0000-000000000001'
   and receptor_id = 'a0000000-0000-0000-0000-000000000003';

-- U1 crea cápsula para U2 y una herencia para U3 que la incluye.
set request.jwt.claim.sub = 'a0000000-0000-0000-0000-000000000001';
insert into public.elementos (
  id, propietario_id, tipo, cloudinary_public_id, cloudinary_tipo_recurso, bytes
) values (
  'e0000000-0000-0000-0000-000000000001',
  'a0000000-0000-0000-0000-000000000001',
  'foto', 'capsoul/u1/h1', 'image', 1000
);
insert into public.capsulas (id, autor_id, titulo, mensaje, fecha_apertura, estado) values (
  'c0000000-0000-0000-0000-000000000001',
  'a0000000-0000-0000-0000-000000000001',
  'Secreto para Dos',
  'no abrir',
  now() + interval '30 days',
  'programada'
);
insert into public.capsula_elementos values (
  'c0000000-0000-0000-0000-000000000001',
  'e0000000-0000-0000-0000-000000000001',
  0
);
insert into public.capsula_destinatarios (capsula_id, usuario_id) values (
  'c0000000-0000-0000-0000-000000000001',
  'a0000000-0000-0000-0000-000000000002'
);

-- Persona de confianza global = U2 (el perfil lo crea el trigger de auth.users)
reset role;
update public.usuarios
   set persona_confianza_legado_id = 'a0000000-0000-0000-0000-000000000002'
 where id = 'a0000000-0000-0000-0000-000000000001';

set role authenticated;
set request.jwt.claim.sub = 'a0000000-0000-0000-0000-000000000001';
insert into public.herencias (
  id, propietario_id, titulo, beneficiario_usuario_id,
  condicion_activacion, fecha_activacion, estado, metadatos
) values (
  'h0000000-0000-0000-0000-000000000001',
  'a0000000-0000-0000-0000-000000000001',
  'Reloj de Tres',
  'a0000000-0000-0000-0000-000000000003',
  'fecha',
  now() + interval '10 days',
  'activa',
  '{"valor_aproximado": 1500000}'::jsonb
);
select public.vincular_capsula_herencia(
  'h0000000-0000-0000-0000-000000000001',
  'c0000000-0000-0000-0000-000000000001'
);

\echo '--- U3 es destinatario por herencia; U2 conserva el suyo'
select usuario_id, origen_herencia_id is not null as por_herencia
  from public.capsula_destinatarios
 where capsula_id = 'c0000000-0000-0000-0000-000000000001'
 order by usuario_id;

\echo '--- U3 no lee el medio de la cápsula programada'
set request.jwt.claim.sub = 'a0000000-0000-0000-0000-000000000003';
select count(*) elementos_u3_antes from public.elementos;
select titulo, contenido_visible from public.herencias_recibidas();

\echo '--- Liberar la herencia NO abre la cápsula'
reset role;
select privado.liberar_herencia('h0000000-0000-0000-0000-000000000001');
select estado as estado_herencia from public.herencias
 where id = 'h0000000-0000-0000-0000-000000000001';
select estado as estado_capsula from public.capsulas
 where id = 'c0000000-0000-0000-0000-000000000001';

set role authenticated;
set request.jwt.claim.sub = 'a0000000-0000-0000-0000-000000000003';
\echo '--- U3 sigue sin el medio (cápsula programada)'
select count(*) elementos_u3_despues from public.elementos;

\echo '--- Cliente no puede insertar herencia_capsulas'
set request.jwt.claim.sub = 'a0000000-0000-0000-0000-000000000001';
insert into public.herencia_capsulas (herencia_id, capsula_id) values (
  'h0000000-0000-0000-0000-000000000001',
  'c0000000-0000-0000-0000-000000000001'
);

reset role;
select tipo, usuario_id from public.notificaciones
 where referencia_id in (
   'h0000000-0000-0000-0000-000000000001',
   'c0000000-0000-0000-0000-000000000001'
 )
 order by tipo, usuario_id;
