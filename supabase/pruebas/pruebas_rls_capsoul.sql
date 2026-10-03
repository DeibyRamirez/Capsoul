-- Capsoul · Pruebas manuales de RLS para la migración 000001 (Postgres local con esquema auth simulado).
-- Ejecutar como postgres sobre una base con la migración aplicada. Ver documento 13 §7.
\set ON_ERROR_STOP 0
-- usuarios A (autor), B (destinatario), C (extraño)
insert into auth.users (id, email, raw_user_meta_data, email_confirmed_at) values
 ('00000000-0000-0000-0000-00000000000a','a@x.co','{"nombre_visible":"Ana"}', now()),
 ('00000000-0000-0000-0000-00000000000b','b@x.co','{"nombre_visible":"Beto"}', now()),
 ('00000000-0000-0000-0000-00000000000c','c@x.co','{}', now());
select id, nombre_visible from public.usuarios order by 1;

-- Como A
set role authenticated; set request.jwt.claim.sub = '00000000-0000-0000-0000-00000000000a';
insert into public.elementos (id, propietario_id, tipo, cloudinary_public_id, cloudinary_tipo_recurso) values ('10000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-00000000000a','foto','capsoul/a/1','image');
insert into public.capsulas (id, autor_id, titulo, mensaje, fecha_apertura, estado) values ('20000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-00000000000a','Para Beto','secreto', now()+interval '1 hour','programada');
insert into public.capsula_elementos values ('20000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001',0);
insert into public.capsula_destinatarios (capsula_id, usuario_id) values ('20000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-00000000000b');
insert into public.capsula_destinatarios (capsula_id, correo_externo) values ('20000000-0000-0000-0000-000000000001','nuevo@x.co');
\echo '--- A intenta liberar (debe fallar)'
update public.capsulas set estado='liberada', liberada_en=now() where id='20000000-0000-0000-0000-000000000001';
\echo '--- A intenta fecha pasada (debe fallar)'
update public.capsulas set fecha_apertura=now()-interval '1 day' where id='20000000-0000-0000-0000-000000000001';
\echo '--- A intenta cambiar correo (debe fallar por GRANT)'
update public.usuarios set correo='z@x.co' where id='00000000-0000-0000-0000-00000000000a';
update public.usuarios set nombre_visible='Ana M' where id='00000000-0000-0000-0000-00000000000a';

-- Como B antes de liberar
set request.jwt.claim.sub = '00000000-0000-0000-0000-00000000000b';
\echo '--- B antes de liberar: capsulas=0, elementos=0, recibidas=1 sin titulo'
select count(*) capsulas_visibles from public.capsulas;
select count(*) elementos_visibles from public.elementos;
select titulo, estado from public.capsulas_recibidas();
\echo '--- B no ve perfil de A (no amigos) -> 0 y 0'
select count(*) from public.usuarios where id='00000000-0000-0000-0000-00000000000a';
select count(*) from public.perfiles_visibles where id='00000000-0000-0000-0000-00000000000a';
\echo '--- B lee su propia fila completa, con correo -> b@x.co'
select correo from public.usuarios where id='00000000-0000-0000-0000-00000000000b';
\echo '--- B no puede llamar funciones de privado que no usan las políticas (debe fallar)'
select privado.liberar_capsulas_vencidas();

reset role;
-- Simular vencimiento y correr el trabajo dos veces (idempotencia)
update public.capsulas set fecha_apertura = now() - interval '1 minute' where id='20000000-0000-0000-0000-000000000001';
select privado.liberar_capsulas_vencidas() as liberadas_1;
select privado.liberar_capsulas_vencidas() as liberadas_2;
select canal, tipo, coalesce(usuario_id::text, correo_destino) destino from public.notificaciones order by 1;

set role authenticated; set request.jwt.claim.sub = '00000000-0000-0000-0000-00000000000b';
\echo '--- B tras liberar: capsulas=1, elementos=1'
select titulo, mensaje from public.capsulas;
select count(*) elementos_visibles from public.elementos;
select public.marcar_capsula_abierta('20000000-0000-0000-0000-000000000001');
\echo '--- C extraño: 0 y 0'
set request.jwt.claim.sub = '00000000-0000-0000-0000-00000000000c';
select count(*) from public.capsulas; select count(*) from public.elementos;
\echo '--- A no puede borrar elemento entregado (0 filas)'
set request.jwt.claim.sub = '00000000-0000-0000-0000-00000000000a';
delete from public.elementos where id='10000000-0000-0000-0000-000000000001';
select count(*) from public.elementos;

-- Amistades y momentos
\echo '--- Amistad A->B, B acepta, B marca a A como cercano'
insert into public.amistades (solicitante_id, receptor_id) values ('00000000-0000-0000-0000-00000000000a','00000000-0000-0000-0000-00000000000b');
\echo '--- A intenta aceptar su propia solicitud (debe fallar)'
update public.amistades set estado='aceptada';
set request.jwt.claim.sub = '00000000-0000-0000-0000-00000000000b';
update public.amistades set estado='aceptada';
\echo '--- Amigo B: ve el perfil de A sin correo por la vista -> 1 fila (Ana M)'
select nombre_visible from public.perfiles_visibles where id='00000000-0000-0000-0000-00000000000a';
\echo '--- Amigo B NO puede leer el correo de A -> 0 filas'
select count(*) correo_A_visible from public.usuarios where id='00000000-0000-0000-0000-00000000000a';
\echo '--- La vista no expone la columna correo (debe fallar)'
select correo from public.perfiles_visibles;
set request.jwt.claim.sub = '00000000-0000-0000-0000-00000000000a';
insert into public.momentos (id, autor_id, texto, visibilidad) values ('30000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-00000000000a','hola cercanos','cercanos');
insert into public.momentos (id, autor_id, texto, visibilidad) values ('30000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-00000000000a','hola amigos','amigos');
set request.jwt.claim.sub = '00000000-0000-0000-0000-00000000000b';
\echo '--- B ve solo el de amigos (A no lo marcó cercano) -> 1'
select texto from public.momentos;
set request.jwt.claim.sub = '00000000-0000-0000-0000-00000000000a';
update public.amistades set cercano_para_solicitante = true;
set request.jwt.claim.sub = '00000000-0000-0000-0000-00000000000b';
\echo '--- ahora 2'
select count(*) from public.momentos;

-- Herencias
set request.jwt.claim.sub = '00000000-0000-0000-0000-00000000000a';
insert into public.herencias (id, propietario_id, titulo, beneficiario_correo, persona_confianza_id, condicion_activacion, estado) values
 ('40000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-00000000000a','Reloj','hijo@x.co','00000000-0000-0000-0000-00000000000c','confirmacion_confianza','activa');
\echo '--- A intenta liberar herencia (debe fallar)'
update public.herencias set estado='liberada', liberada_en=now();
set request.jwt.claim.sub = '00000000-0000-0000-0000-00000000000c';
\echo '--- C (confianza) ve la herencia y confirma'
select titulo, estado from public.herencias;
select public.confirmar_herencia('40000000-0000-0000-0000-000000000001');
reset role;
select estado, liberada_en is not null from public.herencias;
-- Registro del hijo con correo confirmado -> vinculación
insert into auth.users (id, email, email_confirmed_at) values ('00000000-0000-0000-0000-00000000000d','hijo@x.co', now());
select beneficiario_usuario_id from public.herencias;
select canal, tipo, coalesce(usuario_id::text, correo_destino) from public.notificaciones order by tipo;
-- Inactividad
update public.usuarios set ultima_actividad_en = now() - interval '100 days' where id='00000000-0000-0000-0000-00000000000b';
insert into public.herencias (propietario_id, titulo, beneficiario_usuario_id, condicion_activacion, dias_inactividad, estado) values ('00000000-0000-0000-0000-00000000000b','Fotos','00000000-0000-0000-0000-00000000000a','inactividad',90,'activa');
select privado.activar_herencias();
select titulo, estado from public.herencias order by titulo;

-- Perfil público y sincronización de correo
reset role;
update public.usuarios set perfil_publico = true where id='00000000-0000-0000-0000-00000000000c';
set role authenticated; set request.jwt.claim.sub = '00000000-0000-0000-0000-00000000000a';
\echo '--- A ve el perfil público de C por la vista (1) pero no su fila en usuarios (0)'
select count(*) from public.perfiles_visibles where id='00000000-0000-0000-0000-00000000000c';
select count(*) from public.usuarios where id='00000000-0000-0000-0000-00000000000c';
-- Invitaciones pendientes al correo al que A se cambiará (1.3)
set request.jwt.claim.sub = '00000000-0000-0000-0000-00000000000b';
insert into public.capsulas (id, autor_id, titulo, mensaje, fecha_apertura, estado) values ('20000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-00000000000b','Para Ana nueva','hola', now()+interval '1 day','programada');
insert into public.capsula_destinatarios (capsula_id, correo_externo) values ('20000000-0000-0000-0000-000000000002','Ana@Nuevo.co');
set request.jwt.claim.sub = '00000000-0000-0000-0000-00000000000c';
insert into public.herencias (id, propietario_id, titulo, beneficiario_correo, persona_confianza_id, condicion_activacion, estado) values
 ('40000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-00000000000c','Libros','ana@nuevo.co','00000000-0000-0000-0000-00000000000b','confirmacion_confianza','activa');
reset role;
\echo '--- Cambio de correo en auth.users se copia a usuarios.correo -> ana@nuevo.co'
update auth.users set email='ana@nuevo.co' where id='00000000-0000-0000-0000-00000000000a';
select correo from public.usuarios where id='00000000-0000-0000-0000-00000000000a';
\echo '--- 1.3: tras el cambio de correo se vinculan las invitaciones al correo nuevo -> a, a'
select usuario_id from public.capsula_destinatarios where capsula_id='20000000-0000-0000-0000-000000000002';
select beneficiario_usuario_id from public.herencias where id='40000000-0000-0000-0000-000000000002';
set role authenticated; set request.jwt.claim.sub = '00000000-0000-0000-0000-00000000000a';
\echo '--- 1.3: A ya la ve como recibida (1 fila, sin contenido hasta la apertura)'
select count(*) recibidas_para_ana_nueva from public.capsulas_recibidas() where capsula_id='20000000-0000-0000-0000-000000000002';
reset role;
\echo '--- 1.3: cuenta SIN confirmar que cambia de correo: se sincroniza pero NO vincula -> e2@x.co, null'
insert into auth.users (id, email) values ('00000000-0000-0000-0000-00000000000e','e@x.co');
insert into public.capsula_destinatarios (capsula_id, correo_externo) values ('20000000-0000-0000-0000-000000000002','e2@x.co');
update auth.users set email='e2@x.co' where id='00000000-0000-0000-0000-00000000000e';
select correo from public.usuarios where id='00000000-0000-0000-0000-00000000000e';
select usuario_id from public.capsula_destinatarios where correo_externo='e2@x.co';
\echo '--- 1.3: función NUEVA creada por postgres en privado: sin EXECUTE para anon/authenticated -> f, f'
create function privado.prueba_funcion_nueva() returns integer language sql as 'select 1';
select has_function_privilege('anon', 'privado.prueba_funcion_nueva()', 'execute') anon_ejecuta,
       has_function_privilege('authenticated', 'privado.prueba_funcion_nueva()', 'execute') authenticated_ejecuta;
set role authenticated;
\echo '--- 1.3: authenticated la llama (debe fallar: permission denied)'
select privado.prueba_funcion_nueva();
reset role;
drop function privado.prueba_funcion_nueva();
\echo '--- 1.3: la función común de vinculación tampoco es ejecutable por el cliente -> f'
select has_function_privilege('authenticated', 'privado.vincular_invitaciones_correo(uuid, text)', 'execute') authenticated_vincula;
\echo '--- D2: un elemento con entrega upload lo rechaza el CHECK (debe fallar)'
insert into public.elementos (propietario_id, tipo, cloudinary_public_id, cloudinary_tipo_recurso, cloudinary_tipo_entrega)
values ('00000000-0000-0000-0000-00000000000a','foto','k3j9x2m1','image','upload');
