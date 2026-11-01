-- Capsoul · Solicitudes de amistad visibles para el receptor.
-- mis_solicitudes_amistad_pendientes (000013) unía amistades con
-- perfiles_visibles. Esa vista solo incluye al propio usuario, a los amigos
-- ya aceptados y a los perfiles públicos. Una solicitud pendiente no es
-- amistad aceptada y el perfil nace privado, así que el join descartaba la
-- fila: el push salía (el trigger sí inserta el aviso) pero Amigos e
-- invitaciones y Avisos no tenían a quién aceptar o rechazar.
-- La función sigue siendo security definer y solo devuelve nombre y foto del
-- solicitante de las filas donde el llamador es el receptor.

begin;

create or replace function public.mis_solicitudes_amistad_pendientes()
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
         coalesce(nullif(trim(u.nombre_visible), ''), 'Alguien'),
         u.foto_public_id,
         am.creado_en
  from public.amistades am
  join public.usuarios u on u.id = am.solicitante_id
  where am.receptor_id = (select auth.uid())
    and am.estado = 'pendiente'
  order by am.creado_en desc;
$$;

revoke all on function public.mis_solicitudes_amistad_pendientes()
  from public, anon;
grant execute on function public.mis_solicitudes_amistad_pendientes()
  to authenticated;

commit;
