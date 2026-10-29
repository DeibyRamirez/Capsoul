-- Capsoul · Despacho de avisos (DEV-100).
-- Reclama un lote con FOR UPDATE SKIP LOCKED para que dos invocaciones
-- no envíen el mismo aviso. El cron llama a enviar-avisos con la llave
-- del Vault; si faltan project_url o llave_cron, el trabajo no falla.
-- No edita migraciones ya aplicadas. No se aplica en el remoto sin el PO.

begin;

alter table public.notificaciones
  add column reclamado_en timestamptz;

comment on column public.notificaciones.reclamado_en is
  'Marca de reclamo del worker. Null o más vieja de 5 minutos: se puede volver a tomar.';

-- Resultado por dispositivo. El cliente no lee ni escribe esta tabla.
create type public.estado_entrega_push as enum ('pendiente', 'enviada', 'fallida', 'invalida');

create table public.notificacion_entregas (
  id               uuid primary key default gen_random_uuid(),
  notificacion_id  uuid not null references public.notificaciones (id) on delete cascade,
  token_fcm        text not null check (char_length(token_fcm) between 1 and 4096),
  estado           public.estado_entrega_push not null default 'pendiente',
  intentos         smallint not null default 0 check (intentos >= 0),
  ultimo_error     text,
  creado_en        timestamptz not null default now(),
  actualizado_en   timestamptz not null default now(),
  constraint notificacion_entregas_aviso_token_unica unique (notificacion_id, token_fcm)
);

create index notificacion_entregas_notificacion_id_idx
  on public.notificacion_entregas (notificacion_id);

create trigger notificacion_entregas_actualizado
  before update on public.notificacion_entregas
  for each row execute function privado.marcar_actualizado();

alter table public.notificacion_entregas enable row level security;

revoke all on public.notificacion_entregas from public, anon, authenticated;
grant select, insert, update, delete on public.notificacion_entregas to service_role;

-- Toma avisos pendientes que nadie tiene reclamados (o cuyo reclamo quedó colgado).
create or replace function privado.reclamar_avisos(p_lote integer default 25)
returns table (
  id uuid,
  usuario_id uuid,
  correo_destino text,
  canal public.canal_notificacion,
  tipo public.tipo_notificacion,
  referencia_id uuid,
  titulo text,
  cuerpo text,
  intentos smallint
)
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_lote integer;
begin
  v_lote := least(greatest(coalesce(p_lote, 25), 1), 100);
  return query
  update public.notificaciones n
     set reclamado_en = now()
   where n.id in (
     select c.id
       from public.notificaciones c
      where c.estado = 'pendiente'
        and (c.reclamado_en is null or c.reclamado_en < now() - interval '5 minutes')
      order by c.creado_en
      for update skip locked
      limit v_lote
   )
  returning n.id, n.usuario_id, n.correo_destino, n.canal, n.tipo,
            n.referencia_id, n.titulo, n.cuerpo, n.intentos;
end $$;

-- PostgREST solo expone public. La función queda para service_role.
create or replace function public.reclamar_avisos(p_lote integer default 25)
returns table (
  id uuid,
  usuario_id uuid,
  correo_destino text,
  canal public.canal_notificacion,
  tipo public.tipo_notificacion,
  referencia_id uuid,
  titulo text,
  cuerpo text,
  intentos smallint
)
language sql
volatile
security definer
set search_path = ''
as $$
  select * from privado.reclamar_avisos(p_lote);
$$;

revoke all on function privado.reclamar_avisos(integer) from public, anon, authenticated;
revoke all on function public.reclamar_avisos(integer) from public, anon, authenticated;
grant execute on function privado.reclamar_avisos(integer) to service_role;
grant execute on function public.reclamar_avisos(integer) to service_role;

-- El trabajo de pg_cron solo llama a esta función. La URL y la llave salen
-- del Vault. Si no están, o si pg_net falla, el job termina en silencio.
create or replace function privado.invocar_enviar_avisos()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_url text;
  v_llave text;
begin
  if to_regclass('vault.decrypted_secrets') is null then
    return;
  end if;

  begin
    select s.decrypted_secret into v_url
      from vault.decrypted_secrets s
     where s.name = 'project_url'
     limit 1;
    select s.decrypted_secret into v_llave
      from vault.decrypted_secrets s
     where s.name = 'llave_cron'
     limit 1;
  exception
    when others then
      return;
  end;

  if v_url is null or btrim(v_url) = '' or v_llave is null or btrim(v_llave) = '' then
    return;
  end if;

  begin
    perform net.http_post(
      url := rtrim(btrim(v_url), '/') || '/functions/v1/enviar-avisos',
      body := jsonb_build_object('origen', 'cron'),
      params := '{}'::jsonb,
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'x-llave-cron', v_llave
      ),
      timeout_milliseconds := 10000
    );
  exception
    when others then
      return;
  end;
end $$;

revoke all on function privado.invocar_enviar_avisos() from public, anon, authenticated;

-- Reemplaza el job 3 de 000002, que leía el Vault dentro del comando
-- y fallaba si los secretos no existían. El comando nuevo no lleva valores.
do $$
begin
  perform cron.unschedule('capsoul-enviar-avisos');
exception
  when others then
    null;
end $$;

select cron.schedule(
  'capsoul-enviar-avisos',
  '* * * * *',
  $$ select privado.invocar_enviar_avisos(); $$
);

commit;
