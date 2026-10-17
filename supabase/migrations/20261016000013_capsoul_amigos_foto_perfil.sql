-- Capsoul · foto de perfil en listados de amigos y solicitudes (2026-10-16)

drop function if exists public.mis_amigos();

create function public.mis_amigos()
returns table (
  usuario_id uuid,
  nombre_visible text,
  nombre_usuario text,
  foto_public_id text
)
language sql
stable
security definer
set search_path = ''
as $$
  select p.id, p.nombre_visible, p.nombre_usuario, p.foto_public_id
  from public.perfiles_visibles p
  where p.id <> (select auth.uid())
    and privado.son_amigos(p.id, (select auth.uid()))
  order by p.nombre_visible;
$$;

drop function if exists public.mis_solicitudes_amistad_pendientes();

create function public.mis_solicitudes_amistad_pendientes()
returns table (
  amistad_id uuid,
  solicitante_id uuid,
  solicitante_nombre text,
  solicitante_foto_public_id text,
  creado_en timestamptz
)
language sql
stable
security definer
set search_path = ''
as $$
  select am.id,
         am.solicitante_id,
         p.nombre_visible,
         p.foto_public_id,
         am.creado_en
  from public.amistades am
  join public.perfiles_visibles p on p.id = am.solicitante_id
  where am.receptor_id = (select auth.uid())
    and am.estado = 'pendiente'
  order by am.creado_en desc;
$$;

grant execute on function public.mis_amigos() to authenticated;
grant execute on function public.mis_solicitudes_amistad_pendientes() to authenticated;
