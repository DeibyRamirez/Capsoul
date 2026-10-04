-- Capsoul · Pruebas de la migración 000004 (RLS con RETURNING, recuerdos, CAP03, portada de momentos).
-- Ejecutar como postgres en una base LOCAL desechable con esquema auth simulado y las migraciones
-- 000001, 000003 y 000004 aplicadas. Cada "OK ..." es una verificación superada; "FALLO" detiene el script.
\set ON_ERROR_STOP 1
insert into auth.users (id, email, email_confirmed_at) values
  ('11111111-1111-1111-1111-111111111111', 'ana@capsoul.app', now()),
  ('22222222-2222-2222-2222-222222222222', 'beto@capsoul.app', now());

create or replace function pg_temp.espera_error(sql text, estado text) returns text language plpgsql as $$
begin
  execute sql;
  raise exception 'FALLO: no hubo error (se esperaba %): %', estado, sql;
exception when others then
  if sqlstate <> estado then raise exception 'FALLO: % en vez de % (%): %', sqlstate, estado, sqlerrm, sql; end if;
  return 'OK ' || estado || ' ' || left(sql, 70);
end $$;
grant execute on function pg_temp.espera_error(text, text) to authenticated;

set role authenticated;
select set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', false) is not null;

-- 1. INSERT ... RETURNING (como PostgREST insert().select()) ya no da 42501
with s as (insert into public.elementos (id, propietario_id, tipo, contenido_texto, titulo, fecha_recuerdo)
  values ('e0000000-0000-0000-0000-000000000001', auth.uid(), 'texto', 'Primera nota', 'Mi nota', date '2026-09-30') returning id)
  select 'OK elemento con returning' from s;
with s as (insert into public.capsulas (id, autor_id, titulo, fecha_apertura, estado)
  values ('c0000000-0000-0000-0000-000000000001', auth.uid(), 'Para Jacobo', now() + interval '20 years', 'borrador') returning id)
  select 'OK cápsula con returning' from s;
with s as (insert into public.momentos (id, autor_id, titulo) values ('d0000000-0000-0000-0000-000000000001', auth.uid(), 'Viaje a Cali') returning id)
  select 'OK momento con returning' from s;

-- 2. fecha_recuerdo por defecto y título
insert into public.elementos (id, propietario_id, tipo, cloudinary_public_id, cloudinary_tipo_recurso, bytes, ancho, alto)
  values ('e0000000-0000-0000-0000-000000000002', auth.uid(), 'foto', 'capsoul/f1', 'image', 1000, 1600, 1200);
select 'OK fecha por defecto ' || fecha_recuerdo from public.elementos
  where id = 'e0000000-0000-0000-0000-000000000002' and fecha_recuerdo = (creado_en at time zone 'utc')::date;
select pg_temp.espera_error($q$insert into public.elementos (propietario_id, tipo, contenido_texto, titulo) values (auth.uid(), 'texto', 'x', repeat('t', 121))$q$, '23514');
select pg_temp.espera_error($q$insert into public.elementos (propietario_id, tipo, contenido_texto, titulo) values (auth.uid(), 'texto', 'x', '   ')$q$, '23514');
select pg_temp.espera_error($q$insert into public.elementos (propietario_id, tipo, contenido_texto, fecha_recuerdo) values (auth.uid(), 'texto', 'x', date '1800-01-01')$q$, '23514');

-- 3. CAP03: enlazar recuerdos existentes y bloquear su borrado cuando la cápsula está programada
insert into public.capsula_elementos (capsula_id, elemento_id, orden) values
  ('c0000000-0000-0000-0000-000000000001', 'e0000000-0000-0000-0000-000000000001', 0);
-- en borrador todavía se puede borrar (sale de la cápsula)
insert into public.elementos (id, propietario_id, tipo, contenido_texto)
  values ('e0000000-0000-0000-0000-000000000003', auth.uid(), 'texto', 'Borrable');
insert into public.capsula_elementos (capsula_id, elemento_id, orden) values
  ('c0000000-0000-0000-0000-000000000001', 'e0000000-0000-0000-0000-000000000003', 1);
delete from public.elementos where id = 'e0000000-0000-0000-0000-000000000003';
select 'OK borrado en borrador' where not exists (select 1 from public.elementos where id = 'e0000000-0000-0000-0000-000000000003');
update public.capsulas set estado = 'programada' where id = 'c0000000-0000-0000-0000-000000000001';
select pg_temp.espera_error($q$delete from public.elementos where id = 'e0000000-0000-0000-0000-000000000001'$q$, 'CAP03');
-- un recuerdo suelto sí se borra
insert into public.elementos (id, propietario_id, tipo, contenido_texto)
  values ('e0000000-0000-0000-0000-000000000004', auth.uid(), 'texto', 'Suelto');
delete from public.elementos where id = 'e0000000-0000-0000-0000-000000000004';
select 'OK recuerdo suelto borrado' where not exists (select 1 from public.elementos where id = 'e0000000-0000-0000-0000-000000000004');

-- 4. Portada de momentos (CAP04)
select pg_temp.espera_error($q$update public.momentos set portada_elemento_id = 'e0000000-0000-0000-0000-000000000002' where id = 'd0000000-0000-0000-0000-000000000001'$q$, 'CAP04');
insert into public.momento_elementos (momento_id, elemento_id, orden) values
  ('d0000000-0000-0000-0000-000000000001', 'e0000000-0000-0000-0000-000000000002', 0),
  ('d0000000-0000-0000-0000-000000000001', 'e0000000-0000-0000-0000-000000000001', 1);
-- una nota no puede ser portada
select pg_temp.espera_error($q$update public.momentos set portada_elemento_id = 'e0000000-0000-0000-0000-000000000001' where id = 'd0000000-0000-0000-0000-000000000001'$q$, 'CAP04');
update public.momentos set portada_elemento_id = 'e0000000-0000-0000-0000-000000000002' where id = 'd0000000-0000-0000-0000-000000000001';
select 'OK portada fijada' from public.momentos where portada_elemento_id = 'e0000000-0000-0000-0000-000000000002';
select pg_temp.espera_error($q$insert into public.momentos (autor_id, titulo) values (auth.uid(), repeat('m', 81))$q$, '23514');
select pg_temp.espera_error($q$insert into public.momentos (autor_id) values (auth.uid())$q$, '23502');
-- quitar la foto del momento deja la portada en null
delete from public.momento_elementos where momento_id = 'd0000000-0000-0000-0000-000000000001' and elemento_id = 'e0000000-0000-0000-0000-000000000002';
select 'OK portada en null al quitarla' from public.momentos where id = 'd0000000-0000-0000-0000-000000000001' and portada_elemento_id is null;

-- 5. Beto no ve nada de Ana; su RETURNING también funciona
select set_config('request.jwt.claim.sub', '22222222-2222-2222-2222-222222222222', false) is not null;
select 'OK beto no ve elementos ajenos: ' || count(*) from public.elementos having count(*) = 0;
select 'OK beto no ve momentos ajenos: ' || count(*) from public.momentos having count(*) = 0;
select pg_temp.espera_error($q$insert into public.momento_elementos (momento_id, elemento_id) values ('d0000000-0000-0000-0000-000000000001', 'e0000000-0000-0000-0000-000000000002')$q$, '42501');
with s as (insert into public.elementos (propietario_id, tipo, contenido_texto) values (auth.uid(), 'texto', 'De Beto') returning id)
  select 'OK beto con returning' from s;
reset role;

-- 6. Borrar la cuenta (cascada) no se bloquea por CAP03
update public.capsulas set estado = 'programada', fecha_apertura = now() + interval '1 year' where id = 'c0000000-0000-0000-0000-000000000001';
select 'OK cápsula programada con recuerdo: ' || count(*) from public.capsula_elementos where capsula_id = 'c0000000-0000-0000-0000-000000000001';
delete from auth.users where id = '11111111-1111-1111-1111-111111111111';
select 'OK cuenta borrada en cascada (elementos restantes de Ana: ' || count(*) || ')' from public.elementos
  where propietario_id = '11111111-1111-1111-1111-111111111111' having count(*) = 0;
