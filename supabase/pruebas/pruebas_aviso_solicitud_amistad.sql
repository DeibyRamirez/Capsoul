-- Capsoul · Aviso push de solicitud de amistad (migración 000021).
\set ON_ERROR_STOP 1

insert into auth.users (id, email, raw_user_meta_data, email_confirmed_at) values
  ('98000000-0000-0000-0000-0000000000a1', 'solicita-aviso@capsoul.app', '{"nombre_visible":"Ana Aviso"}', now()),
  ('98000000-0000-0000-0000-0000000000b1', 'recibe-aviso@capsoul.app', '{"nombre_visible":"Beto Aviso"}', now()),
  ('98000000-0000-0000-0000-0000000000c1', 'invita-aviso@capsoul.app', '{"nombre_visible":"Caro Aviso"}', now())
on conflict do nothing;

-- 1. Enviar la solicitud encola un aviso push para el receptor.
set role authenticated;
select set_config('request.jwt.claim.sub', '98000000-0000-0000-0000-0000000000a1', false);
select public.enviar_solicitud_amistad('98000000-0000-0000-0000-0000000000b1');
reset role;

do $$
declare
  n integer;
  fila public.notificaciones;
begin
  select count(*) into n
    from public.notificaciones
   where tipo = 'solicitud_amistad'
     and usuario_id = '98000000-0000-0000-0000-0000000000b1';
  if n <> 1 then
    raise exception 'FALLO: se esperaba 1 aviso de solicitud y hay %', n;
  end if;

  select * into fila
    from public.notificaciones
   where tipo = 'solicitud_amistad'
     and usuario_id = '98000000-0000-0000-0000-0000000000b1';
  if fila.canal <> 'push' or fila.estado <> 'pendiente' then
    raise exception 'FALLO: canal o estado inesperado (%, %)', fila.canal, fila.estado;
  end if;
  if fila.referencia_id <> (
    select id from public.amistades
     where solicitante_id = '98000000-0000-0000-0000-0000000000a1'
       and receptor_id = '98000000-0000-0000-0000-0000000000b1'
  ) then
    raise exception 'FALLO: referencia_id no es la amistad';
  end if;
  if fila.cuerpo not like 'Ana Aviso%' then
    raise exception 'FALLO: el cuerpo no nombra al solicitante: %', fila.cuerpo;
  end if;
  if exists (
    select 1 from public.notificaciones
     where tipo = 'solicitud_amistad'
       and usuario_id = '98000000-0000-0000-0000-0000000000a1'
  ) then
    raise exception 'FALLO: el solicitante recibió aviso';
  end if;
end $$;

-- 2. Aceptar la solicitud no encola otro aviso.
update public.amistades
   set estado = 'aceptada', respondido_en = now()
 where solicitante_id = '98000000-0000-0000-0000-0000000000a1'
   and receptor_id = '98000000-0000-0000-0000-0000000000b1';

do $$
declare n integer;
begin
  select count(*) into n from public.notificaciones
   where tipo = 'solicitud_amistad'
     and usuario_id = '98000000-0000-0000-0000-0000000000b1';
  if n <> 1 then
    raise exception 'FALLO: aceptar duplicó el aviso (%)', n;
  end if;
end $$;

-- 3. Una amistad creada ya aceptada (invitación por enlace) no avisa.
insert into public.amistades (solicitante_id, receptor_id, estado, respondido_en)
values ('98000000-0000-0000-0000-0000000000c1', '98000000-0000-0000-0000-0000000000b1', 'aceptada', now());

do $$
begin
  if exists (
    select 1 from public.notificaciones n
      join public.amistades a on a.id = n.referencia_id
     where n.tipo = 'solicitud_amistad'
       and a.solicitante_id = '98000000-0000-0000-0000-0000000000c1'
  ) then
    raise exception 'FALLO: una amistad aceptada generó aviso de solicitud';
  end if;
end $$;

-- 4. Si existe la publicación de Supabase, amistades está en ella.
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime')
     and not exists (
       select 1 from pg_publication_tables
        where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'amistades'
     ) then
    raise exception 'FALLO: amistades no está en supabase_realtime';
  end if;
end $$;

select 'pruebas_aviso_solicitud_amistad OK';
