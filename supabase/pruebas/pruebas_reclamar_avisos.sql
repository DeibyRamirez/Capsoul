-- Capsoul · Reclamo concurrente de avisos (DEV-100).
-- Dos transacciones abiertas no se llevan el mismo id.
\set ON_ERROR_STOP 1

create extension if not exists dblink;

insert into auth.users (id, email, raw_user_meta_data, email_confirmed_at) values
  ('a1000000-0000-0000-0000-0000000000a1', 'aviso-a@capsoul.app', '{"nombre_visible":"AvisoA"}', now())
on conflict do nothing;

create or replace function pg_temp.afirmar(condicion boolean, mensaje text)
returns void language plpgsql as $$
begin
  if not condicion then
    raise exception 'FALLO: %', mensaje;
  end if;
end $$;

insert into public.notificaciones (id, usuario_id, canal, tipo, referencia_id, titulo, cuerpo, creado_en) values
  ('a1100000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-0000000000a1', 'push', 'capsula_liberada', 'a1200000-0000-0000-0000-000000000001', 'Una', 'Cuerpo', now() - interval '10 minutes'),
  ('a1100000-0000-0000-0000-000000000002', 'a1000000-0000-0000-0000-0000000000a1', 'push', 'capsula_liberada', 'a1200000-0000-0000-0000-000000000002', 'Dos', 'Cuerpo', now() - interval '9 minutes'),
  ('a1100000-0000-0000-0000-000000000003', 'a1000000-0000-0000-0000-0000000000a1', 'push', 'capsula_liberada', 'a1200000-0000-0000-0000-000000000003', 'Tres', 'Cuerpo', now() - interval '8 minutes'),
  ('a1100000-0000-0000-0000-000000000004', 'a1000000-0000-0000-0000-0000000000a1', 'push', 'capsula_liberada', 'a1200000-0000-0000-0000-000000000004', 'Cuatro', 'Cuerpo', now() - interval '7 minutes');

-- Aísla la cola: otras pruebas dejan avisos pendientes y el lote es pequeño.
update public.notificaciones
   set estado = 'enviada'
 where estado = 'pendiente'
   and id not in (
     'a1100000-0000-0000-0000-000000000001',
     'a1100000-0000-0000-0000-000000000002',
     'a1100000-0000-0000-0000-000000000003',
     'a1100000-0000-0000-0000-000000000004'
   );

-- El cliente no puede reclamar.
set role authenticated;
select set_config('request.jwt.claim.sub', 'a1000000-0000-0000-0000-0000000000a1', false);
do $$
begin
  begin
    perform public.reclamar_avisos(1);
    raise exception 'FALLO: authenticated pudo reclamar';
  exception when insufficient_privilege then
    null;
  end;
  begin
    perform privado.reclamar_avisos(1);
    raise exception 'FALLO: authenticated pudo reclamar en privado';
  exception when insufficient_privilege then
    null;
  end;
end $$;
reset role;

-- service_role sí puede, y un segundo pase no repite lo recién reclamado.
do $$
declare
  primera integer;
  segunda integer;
begin
  set local role service_role;
  select count(*) into primera from public.reclamar_avisos(1);
  select count(*) into segunda from public.reclamar_avisos(1);
  if primera <> 1 or segunda <> 1 then
    raise exception 'FALLO: el lote de 1 devolvió % y %', primera, segunda;
  end if;
end $$;

do $$
declare
  marcados integer;
begin
  select count(*) into marcados
    from public.notificaciones
   where id in (
     'a1100000-0000-0000-0000-000000000001',
     'a1100000-0000-0000-0000-000000000002'
   ) and reclamado_en is not null;
  if marcados <> 2 then
    raise exception 'FALLO: los dos primeros no quedaron reclamados (%)', marcados;
  end if;
end $$;

-- Suelta el reclamo reciente de los cuatro para el ensayo concurrente,
-- salvo que el bloque anterior ya tomó dos. Los deja libres otra vez.
update public.notificaciones
   set reclamado_en = null, estado = 'pendiente'
 where id in (
   'a1100000-0000-0000-0000-000000000001',
   'a1100000-0000-0000-0000-000000000002',
   'a1100000-0000-0000-0000-000000000003',
   'a1100000-0000-0000-0000-000000000004'
 );

create temp table reclamo_s1 (id uuid);
create temp table reclamo_s2 (id uuid);

select dblink_connect('s1', 'host=/var/run/postgresql dbname=postgres user=postgres');
select dblink_connect('s2', 'host=/var/run/postgresql dbname=postgres user=postgres');
select dblink_exec('s1', 'begin');
select dblink_exec('s2', 'begin');

insert into reclamo_s1
select id from dblink('s1', 'select id from privado.reclamar_avisos(2)') as t(id uuid);

insert into reclamo_s2
select id from dblink('s2', 'select id from privado.reclamar_avisos(2)') as t(id uuid);

do $$
declare
  n1 integer;
  n2 integer;
  repetidos integer;
begin
  select count(*) into n1 from reclamo_s1;
  select count(*) into n2 from reclamo_s2;
  select count(*) into repetidos from (
    select id from reclamo_s1
    intersect
    select id from reclamo_s2
  ) t;
  if n1 <> 2 or n2 <> 2 then
    raise exception 'FALLO: las sesiones tomaron % y % (se esperaban 2 y 2)', n1, n2;
  end if;
  if repetidos <> 0 then
    raise exception 'FALLO: las dos sesiones reclamaron el mismo aviso';
  end if;
end $$;

select dblink_exec('s1', 'commit');
select dblink_exec('s2', 'commit');
select dblink_disconnect('s1');
select dblink_disconnect('s2');

do $$
declare
  marcados integer;
  otra integer;
begin
  select count(*) into marcados
    from public.notificaciones
   where id in (
     'a1100000-0000-0000-0000-000000000001',
     'a1100000-0000-0000-0000-000000000002',
     'a1100000-0000-0000-0000-000000000003',
     'a1100000-0000-0000-0000-000000000004'
   ) and reclamado_en is not null and estado = 'pendiente';
  if marcados <> 4 then
    raise exception 'FALLO: quedaron % avisos reclamados de 4', marcados;
  end if;

  select count(*) into otra from privado.reclamar_avisos(10)
   where id in (
     'a1100000-0000-0000-0000-000000000001',
     'a1100000-0000-0000-0000-000000000002',
     'a1100000-0000-0000-0000-000000000003',
     'a1100000-0000-0000-0000-000000000004'
   );
  if otra <> 0 then
    raise exception 'FALLO: un reclamo reciente volvió a salir (% filas)', otra;
  end if;
end $$;

-- Un reclamo colgado más de 5 minutos se puede volver a tomar.
insert into public.notificaciones (id, usuario_id, canal, tipo, referencia_id, titulo, cuerpo, reclamado_en) values
  ('a1100000-0000-0000-0000-000000000005', 'a1000000-0000-0000-0000-0000000000a1', 'push', 'reto', 'a1200000-0000-0000-0000-000000000005', 'Viejo', 'Cuerpo', now() - interval '6 minutes'),
  ('a1100000-0000-0000-0000-000000000006', 'a1000000-0000-0000-0000-0000000000a1', 'push', 'solicitud_amistad', 'a1200000-0000-0000-0000-000000000006', 'Fresco', 'Cuerpo', now());

do $$
declare
  ids uuid[];
begin
  select array_agg(id) into ids from privado.reclamar_avisos(10);
  if not ('a1100000-0000-0000-0000-000000000005' = any (coalesce(ids, array[]::uuid[]))) then
    raise exception 'FALLO: no se reclamó el aviso con reclamo vencido';
  end if;
  if 'a1100000-0000-0000-0000-000000000006' = any (coalesce(ids, array[]::uuid[])) then
    raise exception 'FALLO: se reclamó un aviso tomado hace un instante';
  end if;
end $$;

-- Sin Vault el cron no debe lanzar error.
select privado.invocar_enviar_avisos();

do $$
declare
  trabajos integer;
  comando text;
begin
  select count(*), min(command) into trabajos, comando
    from cron.job
   where jobname = 'capsoul-enviar-avisos';
  if trabajos <> 1 then
    raise exception 'FALLO: hay % trabajos capsoul-enviar-avisos', trabajos;
  end if;
  if comando not like '%invocar_enviar_avisos%' then
    raise exception 'FALLO: el job no llama a invocar_enviar_avisos: %', comando;
  end if;
  if comando like '%decrypted_secret%' or comando like '%llave_cron%' then
    raise exception 'FALLO: el comando del job lleva secretos o lee el Vault: %', comando;
  end if;
end $$;

select 'OK reclamar avisos' as r;
