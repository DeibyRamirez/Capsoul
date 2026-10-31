-- Capsoul – Música desde la API pública de Deezer.
-- Versión 1.0 – 2026-10-30. Requiere 000005, 000006, 000007 y 000015.
--
-- 1. `elementos.musica_proveedor` admite 'deezer' además de 'spotify'
--    (las filas antiguas de Spotify siguen siendo válidas).
-- 2. Para Deezer solo se guardan metadatos: id, título, artista, portada y
--    enlace. La URL del preview de 30 s caduca, así que NO se guarda
--    (`musica_preview_url` debe ser null): la app vuelve a pedir
--    https://api.deezer.com/track/<id> al reproducir. Nunca se guarda audio.
-- 3. RLS: sin cambios; las políticas de `elementos` ya cubren las columnas
--    musica_*. Grants: sin columnas nuevas; el GRANT UPDATE por columnas de la
--    000007 ya incluye musica_proveedor, musica_preview_url, etc.
--
-- No aplicada en remoto: requiere aprobación del PO.

begin;

alter table public.elementos drop constraint if exists elementos_musica_proveedor_valido;
alter table public.elementos add constraint elementos_musica_proveedor_valido check (
  musica_proveedor is null or musica_proveedor in ('spotify', 'deezer')
);

alter table public.elementos drop constraint if exists elementos_musica_coherente;
alter table public.elementos add constraint elementos_musica_coherente check (
  (
    musica_id_externo is null
    and musica_proveedor is null
    and musica_titulo is null
    and musica_artista is null
    and musica_url_completa is null
  )
  or (
    musica_id_externo is not null
    and musica_proveedor in ('spotify', 'deezer')
    and musica_titulo is not null and btrim(musica_titulo) <> ''
    and musica_artista is not null and btrim(musica_artista) <> ''
    and musica_url_completa is not null and btrim(musica_url_completa) <> ''
    and tipo in ('musica', 'foto')
  )
);

-- Deezer: id numérico y sin URL de preview guardada (caduca).
alter table public.elementos drop constraint if exists elementos_musica_deezer_coherente;
alter table public.elementos add constraint elementos_musica_deezer_coherente check (
  musica_proveedor is distinct from 'deezer'
  or (
    musica_id_externo ~ '^[0-9]{1,20}$'
    and musica_preview_url is null
  )
);

comment on column public.elementos.musica_proveedor is
  'Catálogo de la pista: deezer (actual) o spotify (filas antiguas).';
comment on column public.elementos.musica_preview_url is
  'Solo filas antiguas de Spotify. En Deezer es null: la URL caduca y se pide de nuevo por id.';

commit;
