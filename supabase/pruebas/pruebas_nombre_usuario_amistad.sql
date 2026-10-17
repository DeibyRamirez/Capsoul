-- Capsoul · Pruebas nombre_usuario y solicitud por @ (requiere JWT de prueba)

-- insert test users via postgres role omitted; usar IDs del fixture de pruebas_amistad_compartir

\set request.jwt.claim.sub '00000000-0000-0000-0000-00000000020a'
select public.establecer_mi_nombre_usuario('sharea');

\set request.jwt.claim.sub '00000000-0000-0000-0000-00000000020b'
select public.establecer_mi_nombre_usuario('shareb');

\set request.jwt.claim.sub '00000000-0000-0000-0000-00000000020b'
select usuario_id, nombre_visible from public.resolver_usuario_por_arroba('sharea');

\set request.jwt.claim.sub '00000000-0000-0000-0000-00000000020b'
select public.enviar_solicitud_amistad('00000000-0000-0000-0000-00000000020a');

\set request.jwt.claim.sub '00000000-0000-0000-0000-00000000020a'
select amistad_id, solicitante_nombre from public.mis_solicitudes_amistad_pendientes();
