-- Origen del preview de 30 s (spotify | deezer) al persistir el recuerdo música.
alter table public.elementos
  add column if not exists musica_preview_proveedor text;

alter table public.elementos drop constraint if exists elementos_musica_preview_proveedor_coherente;
alter table public.elementos add constraint elementos_musica_preview_proveedor_coherente check (
  musica_preview_proveedor is null
  or musica_preview_proveedor in ('spotify', 'deezer')
);
