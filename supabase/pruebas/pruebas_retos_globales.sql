-- Prueba manual: retos globales y criterio foto con música
-- Ejecutar tras aplicar migración 20261011000011 con roles de prueba.

-- set role authenticated; set request.jwt.claim.sub = '<uid-prueba>';
-- insert into public.elementos (...) tipo foto + musica_id_externo;
-- select * from public.listar_retos_globales();
-- select public.contar_retos_pendientes();
