-- =====================================================================
-- Capsoul · Elemento música (referencias Spotify, sin Cloudinary)
-- Versión: 1.1 · 2026-10-05
-- Requiere: 20261003000003_capsoul_limites_medios.sql
-- El valor nuevo del enum debe confirmarse antes de usarlo en CHECK (55P04).
-- =====================================================================

alter type public.tipo_elemento add value if not exists 'musica';

begin;

alter table public.elementos
  add column if not exists musica_proveedor text,
  add column if not exists musica_id_externo text,
  add column if not exists musica_titulo text,
  add column if not exists musica_artista text,
  add column if not exists musica_preview_url text,
  add column if not exists musica_url_completa text,
  add column if not exists musica_portada_url text,
  add column if not exists musica_uri_profundo text;

alter table public.elementos drop constraint if exists elementos_contenido_coherente;
alter table public.elementos add constraint elementos_contenido_coherente check (
  (tipo = 'texto' and contenido_texto is not null and cloudinary_public_id is null)
  or
  (tipo = 'musica'
    and cloudinary_public_id is null
    and cloudinary_tipo_recurso is null
    and musica_id_externo is not null)
  or
  (tipo in ('foto', 'video', 'audio')
    and cloudinary_public_id is not null
    and cloudinary_tipo_recurso is not null)
);

alter table public.elementos drop constraint if exists elementos_tipo_recurso_coherente;
alter table public.elementos add constraint elementos_tipo_recurso_coherente check (
  (tipo in ('texto', 'musica') and cloudinary_tipo_recurso is null)
  or (tipo = 'foto' and cloudinary_tipo_recurso = 'image')
  or (tipo in ('video', 'audio') and cloudinary_tipo_recurso = 'video')
);

alter table public.elementos drop constraint if exists elementos_bytes_limite;
alter table public.elementos add constraint elementos_bytes_limite check (
  case tipo
    when 'texto' then true
    when 'musica' then bytes is null
    when 'foto'  then bytes is not null and bytes <= 2097152
    when 'video' then bytes is not null and bytes <= 20971520
    when 'audio' then bytes is not null and bytes <= 3145728
  end
);

alter table public.elementos drop constraint if exists elementos_duracion_limite;
alter table public.elementos add constraint elementos_duracion_limite check (
  case tipo
    when 'video' then duracion_segundos is not null and duracion_segundos > 0 and duracion_segundos <= 61
    when 'audio' then duracion_segundos is not null and duracion_segundos > 0 and duracion_segundos <= 301
    when 'musica' then duracion_segundos is null
      or (duracion_segundos > 0 and duracion_segundos <= 30)
    else duracion_segundos is null
  end
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
    and musica_proveedor = 'spotify'
    and musica_titulo is not null and btrim(musica_titulo) <> ''
    and musica_artista is not null and btrim(musica_artista) <> ''
    and musica_url_completa is not null and btrim(musica_url_completa) <> ''
    and tipo in ('musica', 'foto')
  )
);

alter table public.elementos drop constraint if exists elementos_musica_proveedor_valido;
alter table public.elementos add constraint elementos_musica_proveedor_valido check (
  musica_proveedor is null or musica_proveedor = 'spotify'
);

create or replace function privado.bytes_usados(p_usuario uuid)
returns bigint language sql stable security definer set search_path = '' as $$
  select coalesce(sum(e.bytes), 0)::bigint
  from public.elementos e
  where e.propietario_id = p_usuario
    and e.bytes is not null;
$$;

commit;
