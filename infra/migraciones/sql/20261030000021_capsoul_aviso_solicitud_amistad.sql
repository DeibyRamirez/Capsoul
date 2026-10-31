-- Capsoul · Aviso push de solicitud de amistad y tiempo real de amistades.
-- Al crear una solicitud pendiente (o volver una fila a 'pendiente') se encola
-- un aviso 'solicitud_amistad' para el receptor. enviar-avisos ya lo despacha
-- con el cron de la 000018. El índice notificaciones_idempotencia evita
-- duplicados (tipo, referencia_id = amistades.id, canal, usuario).
-- Además, amistades entra en la publicación supabase_realtime para que la app
-- refresque la lista sin recargar (RLS amistades_leer filtra los eventos).

begin;

create or replace function privado.encolar_aviso_solicitud_amistad()
returns trigger
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_nombre text;
begin
  if new.estado <> 'pendiente' then
    return new;
  end if;
  if tg_op = 'UPDATE' and old.estado = 'pendiente' then
    return new;
  end if;

  select nullif(trim(u.nombre_visible), '')
    into v_nombre
    from public.usuarios u
   where u.id = new.solicitante_id;

  insert into public.notificaciones (usuario_id, canal, tipo, referencia_id, titulo, cuerpo)
  values (
    new.receptor_id,
    'push',
    'solicitud_amistad',
    new.id,
    'Nueva solicitud de amistad',
    coalesce(v_nombre, 'Alguien') || ' quiere ser tu amigo en Capsoul.'
  )
  on conflict do nothing;

  return new;
end;
$$;

revoke all on function privado.encolar_aviso_solicitud_amistad() from public, anon, authenticated;

drop trigger if exists amistades_encolar_aviso on public.amistades;
create trigger amistades_encolar_aviso
  after insert or update of estado on public.amistades
  for each row execute function privado.encolar_aviso_solicitud_amistad();

-- Tiempo real: solo si la publicación existe (en Postgres local de CI no hay).
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime')
     and not exists (
       select 1 from pg_publication_tables
        where pubname = 'supabase_realtime'
          and schemaname = 'public'
          and tablename = 'amistades'
     ) then
    alter publication supabase_realtime add table public.amistades;
  end if;
end $$;

commit;
