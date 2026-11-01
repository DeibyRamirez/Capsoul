-- Capsoul · Endurecimiento de permisos, search_path e índices de llaves foráneas.
-- a) Tablas de legado: se quitan los privilegios por defecto (TRUNCATE,
--    REFERENCES, TRIGGER, UPDATE, etc.) y anon queda sin acceso. A authenticated
--    se le devuelve solo lo que cubren las políticas RLS de 000014. La app no
--    lee estas tablas directo (usa RPC SECURITY DEFINER: herencia_detalle,
--    vincular_capsula_herencia, solicitar_respaldo_legal_herencia), así que
--    esto no cambia ningún flujo actual.
-- b) mis_amigos y mis_solicitudes_amistad_pendientes son funciones sin
--    argumentos (000013): solo authenticated puede ejecutarlas.
-- c) search_path = '' en las SECURITY DEFINER que tenían 'public' o
--    'public, privado'. Sus cuerpos ya califican todo (public., privado.,
--    auth.uid()); now(), count() y coalesce() viven en pg_catalog, que
--    siempre se busca. No hace falta recrearlas.
-- d) Índices para llaves foráneas sin índice.
-- No edita migraciones ya aplicadas. No se aplica en el remoto sin el PO.

begin;

-- a) Tablas de legado
revoke all on public.herencia_capsulas from anon, authenticated, public;
revoke all on public.herencia_eventos from anon, authenticated, public;
revoke all on public.herencia_solicitudes_legal from anon, authenticated, public;

grant select, insert, delete on public.herencia_capsulas to authenticated;
grant select on public.herencia_eventos to authenticated;
grant select, insert on public.herencia_solicitudes_legal to authenticated;

-- b) RPC de amistades
revoke execute on function public.mis_amigos() from anon, public;
revoke execute on function public.mis_solicitudes_amistad_pendientes() from anon, public;
grant execute on function public.mis_amigos() to authenticated;
grant execute on function public.mis_solicitudes_amistad_pendientes() to authenticated;

-- c) search_path fijo y vacío
alter function privado.cumple_criterio_reto(uuid, text, jsonb) set search_path = '';
alter function privado.evaluar_retos_globales(uuid) set search_path = '';
alter function privado.trg_evaluar_retos_elementos() set search_path = '';
alter function privado.trg_evaluar_retos_capsulas() set search_path = '';
alter function privado.trg_evaluar_retos_momentos() set search_path = '';
alter function privado.trg_evaluar_retos_amistades() set search_path = '';
alter function privado.trg_evaluar_retos_usuarios() set search_path = '';
alter function privado.trg_evaluar_retos_herencias() set search_path = '';
alter function public.listar_retos_globales() set search_path = '';
alter function public.contar_retos_pendientes() set search_path = '';
alter function privado.encolar_borrado_medio() set search_path = '';

-- d) Índices de llaves foráneas
create index if not exists reto_participantes_elemento_idx
  on public.reto_participantes (elemento_id);
create index if not exists reto_participantes_capsula_idx
  on public.reto_participantes (capsula_id);
create index if not exists usuarios_persona_confianza_legado_idx
  on public.usuarios (persona_confianza_legado_id);
create index if not exists herencia_eventos_actor_idx
  on public.herencia_eventos (actor_id);
create index if not exists herencia_solicitudes_legal_solicitante_idx
  on public.herencia_solicitudes_legal (solicitante_id);

commit;
