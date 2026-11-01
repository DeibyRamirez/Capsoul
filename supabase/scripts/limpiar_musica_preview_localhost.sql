-- Limpieza opcional: URLs de preview inválidas (dev / pruebas locales).
-- Ejecutar en Supabase SQL Editor solo con aprobación del PO.
-- Tras esto, la app volverá a pedir el clip a Deezer al reproducir.

select id, musica_proveedor, musica_preview_url, musica_titulo
from public.elementos
where musica_preview_url ilike '%127.0.0.1%'
   or musica_preview_url ilike '%localhost%';

-- update public.elementos
-- set musica_preview_url = null
-- where musica_preview_url ilike '%127.0.0.1%'
--    or musica_preview_url ilike '%localhost%';
