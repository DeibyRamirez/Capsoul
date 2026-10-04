-- Capsoul · Pruebas de la migración 000003 (límites de medios, máximo 10 elementos, cuota 200 MB).
-- Ejecutar como postgres en una base LOCAL desechable con esquema auth simulado y las migraciones
-- 000001 y 000003 aplicadas. Cada línea "OK ..." es una verificación superada; un ERROR "FALLO" detiene el script.
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
grant execute on function pg_temp.espera_error(text, text) to authenticated, anon;

set role authenticated;
select set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', false);

-- válidos
insert into public.elementos (propietario_id, tipo, contenido_texto) values (auth.uid(), 'texto', repeat('a', 5000));
insert into public.elementos (propietario_id, tipo, cloudinary_public_id, cloudinary_tipo_recurso, bytes, ancho, alto)
  values (auth.uid(), 'foto', 'capsoul/f1', 'image', 2097152, 1600, 1200);
insert into public.elementos (propietario_id, tipo, cloudinary_public_id, cloudinary_tipo_recurso, bytes, duracion_segundos)
  values (auth.uid(), 'audio', 'capsoul/a1', 'video', 2400000, 300.4);
select 'OK válidos insertados' as r;

-- inválidos (23514)
select pg_temp.espera_error($q$insert into public.elementos (propietario_id, tipo, contenido_texto) values (auth.uid(), 'texto', repeat('a', 5001))$q$, '23514');
select pg_temp.espera_error($q$insert into public.elementos (propietario_id, tipo, contenido_texto) values (auth.uid(), 'texto', '')$q$, '23514');
select pg_temp.espera_error($q$insert into public.elementos (propietario_id, tipo, cloudinary_public_id, cloudinary_tipo_recurso, bytes) values (auth.uid(), 'foto', 'capsoul/f2', 'image', 2097153)$q$, '23514');
select pg_temp.espera_error($q$insert into public.elementos (propietario_id, tipo, cloudinary_public_id, cloudinary_tipo_recurso, bytes) values (auth.uid(), 'foto', 'capsoul/f3', 'image', null)$q$, '23514');
select pg_temp.espera_error($q$insert into public.elementos (propietario_id, tipo, cloudinary_public_id, cloudinary_tipo_recurso, bytes) values (auth.uid(), 'foto', 'capsoul/f4', 'video', 10)$q$, '23514');
select pg_temp.espera_error($q$insert into public.elementos (propietario_id, tipo, cloudinary_public_id, cloudinary_tipo_recurso, bytes, ancho, alto) values (auth.uid(), 'foto', 'capsoul/f5', 'image', 10, 2000, 1000)$q$, '23514');
select pg_temp.espera_error($q$insert into public.elementos (propietario_id, tipo, cloudinary_public_id, cloudinary_tipo_recurso, bytes, duracion_segundos) values (auth.uid(), 'video', 'capsoul/v1', 'video', 1000, 62)$q$, '23514');
select pg_temp.espera_error($q$insert into public.elementos (propietario_id, tipo, cloudinary_public_id, cloudinary_tipo_recurso, bytes, duracion_segundos) values (auth.uid(), 'video', 'capsoul/v2', 'video', 20971521, 30)$q$, '23514');
select pg_temp.espera_error($q$insert into public.elementos (propietario_id, tipo, cloudinary_public_id, cloudinary_tipo_recurso, bytes) values (auth.uid(), 'video', 'capsoul/v3', 'video', 1000)$q$, '23514');
select pg_temp.espera_error($q$insert into public.elementos (propietario_id, tipo, cloudinary_public_id, cloudinary_tipo_recurso, bytes, duracion_segundos) values (auth.uid(), 'audio', 'capsoul/a2', 'video', 3145729, 100)$q$, '23514');
select pg_temp.espera_error($q$insert into public.elementos (propietario_id, tipo, cloudinary_public_id, cloudinary_tipo_recurso, bytes, duracion_segundos) values (auth.uid(), 'audio', 'capsoul/a3', 'video', 1000, 302)$q$, '23514');

-- flujo de la app: borrador -> enlaces -> programada, máximo 10 (CAP02)
insert into public.capsulas (id, autor_id, titulo, fecha_apertura, estado)
  values ('aaaaaaaa-0000-0000-0000-000000000001', auth.uid(), 'Para Jacobo', now() + interval '20 years', 'borrador');
insert into public.elementos (id, propietario_id, tipo, contenido_texto)
  select ('bbbbbbbb-0000-0000-0000-0000000000' || lpad(i::text, 2, '0'))::uuid, auth.uid(), 'texto', 'nota ' || i
  from generate_series(1, 11) i;
insert into public.capsula_elementos (capsula_id, elemento_id, orden)
  select 'aaaaaaaa-0000-0000-0000-000000000001', ('bbbbbbbb-0000-0000-0000-0000000000' || lpad(i::text, 2, '0'))::uuid, i
  from generate_series(1, 10) i;
select pg_temp.espera_error($q$insert into public.capsula_elementos (capsula_id, elemento_id, orden) values ('aaaaaaaa-0000-0000-0000-000000000001', 'bbbbbbbb-0000-0000-0000-000000000011', 11)$q$, 'CAP02');
update public.capsulas set estado = 'programada' where id = 'aaaaaaaa-0000-0000-0000-000000000001';
select 'OK programada con ' || count(*) || ' elementos' from public.capsula_elementos where capsula_id = 'aaaaaaaa-0000-0000-0000-000000000001';

-- compensación de la app: una cápsula en borrador se puede borrar
insert into public.capsulas (id, autor_id, titulo, estado) values ('aaaaaaaa-0000-0000-0000-000000000002', auth.uid(), 'Borrador', 'borrador');
delete from public.capsulas where id = 'aaaaaaaa-0000-0000-0000-000000000002';
select 'OK borrador eliminado' where not exists (select 1 from public.capsulas where id = 'aaaaaaaa-0000-0000-0000-000000000002');

-- cuota: ya hay 2 097 152 + 2 400 000 bytes; 9 videos de 20 MB = 188 743 680 -> total 193 240 832 (cabe)
insert into public.elementos (propietario_id, tipo, cloudinary_public_id, cloudinary_tipo_recurso, bytes, duracion_segundos)
  select auth.uid(), 'video', 'capsoul/cuota' || i, 'video', 20971520, 60 from generate_series(1, 9) i;
select 'OK uso ' || bytes_usados || ' de ' || bytes_limite from public.mi_uso_medios();
select pg_temp.espera_error($q$insert into public.elementos (propietario_id, tipo, cloudinary_public_id, cloudinary_tipo_recurso, bytes, duracion_segundos) values (auth.uid(), 'video', 'capsoul/cuota10', 'video', 20971520, 60)$q$, 'CAP01');
-- un audio pequeño todavía cabe (200 MB - 193 240 832 = 6 474 368)
insert into public.elementos (propietario_id, tipo, cloudinary_public_id, cloudinary_tipo_recurso, bytes, duracion_segundos)
  values (auth.uid(), 'audio', 'capsoul/cuota-a', 'video', 3000000, 200);
-- update de bytes también se valida
select pg_temp.espera_error($q$update public.elementos set bytes = 20971520 where cloudinary_public_id = 'capsoul/cuota-a'$q$, 'CAP01');

-- la cuota es por usuario: Beto empieza en 0
select set_config('request.jwt.claim.sub', '22222222-2222-2222-2222-222222222222', false);
select 'OK beto usa ' || bytes_usados from public.mi_uso_medios();
insert into public.elementos (propietario_id, tipo, cloudinary_public_id, cloudinary_tipo_recurso, bytes, duracion_segundos)
  values (auth.uid(), 'video', 'capsoul/beto1', 'video', 20971520, 60);

-- permisos: authenticated no ejecuta funciones de privado; anon no ejecuta mi_uso_medios
select pg_temp.espera_error($q$select privado.bytes_usados(auth.uid())$q$, '42501');
reset role;
set role anon;
select pg_temp.espera_error($q$select * from public.mi_uso_medios()$q$, '42501');
reset role;
select 'OK permisos: ' || has_function_privilege('authenticated', 'public.mi_uso_medios()', 'execute')::text
  || ' / anon ' || has_function_privilege('anon', 'public.mi_uso_medios()', 'execute')::text
  || ' / privado ' || has_function_privilege('authenticated', 'privado.validar_cuota_medios()', 'execute')::text;
