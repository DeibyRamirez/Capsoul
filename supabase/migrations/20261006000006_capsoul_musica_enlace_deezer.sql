-- Enlace opcional a pista Deezer (cuando el preview proviene del fallback Deezer).

alter table public.elementos
  add column if not exists musica_enlace_deezer text;

comment on column public.elementos.musica_enlace_deezer is
  'URL de pista en Deezer si se resolvió en búsqueda (preview fallback).';
