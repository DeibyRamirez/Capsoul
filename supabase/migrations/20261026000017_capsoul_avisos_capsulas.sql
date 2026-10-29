-- Capsoul · Avisos de cápsulas compartidas (badge de la campanita).
-- notificaciones es la bandeja de salida de push y correo (DEV-100).
-- El aviso de la app vive en el destinatario: leida_en es «ya vi el aviso».
-- abierta_en sigue siendo «ya abrí el frasco» y no se toca aquí.
-- No edita migraciones ya aplicadas. No se aplica en el remoto sin el PO.

begin;

alter table public.capsula_destinatarios
  add column leida_en timestamptz;

-- El badge cuenta las filas del usuario que aún no leyó.
create index capsula_destinatarios_sin_leer_idx
  on public.capsula_destinatarios (usuario_id)
  where usuario_id is not null and leida_en is null;

-- El cliente no tiene UPDATE sobre la tabla. Solo esta función marca el aviso,
-- y solo si la cápsula ya está liberada y la envió otra persona.
create or replace function public.marcar_aviso_capsula_leido(p_capsula uuid)
returns void
language sql
volatile
security definer
set search_path = ''
as $$
  update public.capsula_destinatarios d
     set leida_en = coalesce(d.leida_en, now())
    from public.capsulas c
   where d.capsula_id = p_capsula
     and c.id = d.capsula_id
     and c.estado = 'liberada'
     and c.autor_id is distinct from (select auth.uid())
     and d.usuario_id = (select auth.uid());
$$;

revoke all on function public.marcar_aviso_capsula_leido(uuid) from public, anon;
grant execute on function public.marcar_aviso_capsula_leido(uuid) to authenticated;

commit;
