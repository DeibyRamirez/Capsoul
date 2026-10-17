-- Capsoul · GRANT UPDATE por columnas (DEV-94) · 2026-10-12
-- Restringe qué columnas puede tocar el rol authenticated vía PostgREST.

revoke update on public.capsulas from authenticated;
grant update (titulo, mensaje, fecha_apertura, estado) on public.capsulas to authenticated;

revoke update on public.elementos from authenticated;
grant update (
  titulo,
  fecha_recuerdo,
  musica_proveedor,
  musica_id_externo,
  musica_titulo,
  musica_artista,
  musica_preview_url,
  musica_url_completa,
  musica_portada_url,
  musica_uri_profundo,
  musica_enlace_deezer
) on public.elementos to authenticated;

revoke update on public.momentos from authenticated;
grant update (titulo, texto, visibilidad, portada_elemento_id) on public.momentos to authenticated;
