-- migrate:up

alter table public.elementos
  add column if not exists musica_enlace_deezer text;

comment on column public.elementos.musica_enlace_deezer is
  'URL de pista en Deezer si se resolvió en búsqueda (preview fallback).';

-- migrate:down

alter table public.elementos drop column if exists musica_enlace_deezer;
