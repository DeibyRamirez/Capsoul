-- Capsoul · Aserciones de privado.liberar_capsulas_vencidas() (DEV-99).
-- Idempotencia: una vencida se libera una vez; repetir o solapar no duplica avisos.
\set ON_ERROR_STOP 1

create extension if not exists dblink;

insert into auth.users (id, email, raw_user_meta_data, email_confirmed_at) values
  ('95000000-0000-0000-0000-0000000000a1', 'lib-a@capsoul.app', '{"nombre_visible":"LibA"}', now()),
  ('95000000-0000-0000-0000-0000000000b1', 'lib-b@capsoul.app', '{"nombre_visible":"LibB"}', now())
on conflict do nothing;

-- Datos como postgres: el trigger solo bloquea al rol authenticated.
insert into public.capsulas (id, autor_id, titulo, fecha_apertura, estado) values
  ('95100000-0000-0000-0000-000000000001', '95000000-0000-0000-0000-0000000000a1', 'Vencida', now() - interval '2 minutes', 'programada'),
  ('95100000-0000-0000-0000-000000000002', '95000000-0000-0000-0000-0000000000a1', 'Futura', now() + interval '2 days', 'programada'),
  ('95100000-0000-0000-0000-000000000003', '95000000-0000-0000-0000-0000000000a1', 'Borrador', now() - interval '2 minutes', 'borrador'),
  ('95100000-0000-0000-0000-000000000004', '95000000-0000-0000-0000-0000000000a1', 'Cancelada', now() - interval '2 minutes', 'cancelada');

insert into public.capsula_destinatarios (capsula_id, usuario_id) values
  ('95100000-0000-0000-0000-000000000001', '95000000-0000-0000-0000-0000000000b1');
insert into public.capsula_destinatarios (capsula_id, correo_externo) values
  ('95100000-0000-0000-0000-000000000001', 'externo@capsoul.app');

create or replace function pg_temp.afirmar(condicion boolean, mensaje text)
returns void language plpgsql as $$
begin
  if not condicion then
    raise exception 'FALLO: %', mensaje;
  end if;
end $$;

-- El cliente no puede ejecutar la función.
set role authenticated;
select set_config('request.jwt.claim.sub', '95000000-0000-0000-0000-0000000000a1', false);
do $$
begin
  begin
    perform privado.liberar_capsulas_vencidas();
    raise exception 'FALLO: authenticated pudo liberar';
  exception when insufficient_privilege then
    null;
  end;
end $$;
reset role;

-- Primera pasada: solo la vencida.
do $$
declare
  liberadas integer;
  avisos integer;
  estado_real public.estado_capsula;
  marca timestamptz;
begin
  liberadas := privado.liberar_capsulas_vencidas();
  if liberadas <> 1 then
    raise exception 'FALLO: la primera pasada liberó % (se esperaba 1)', liberadas;
  end if;

  select c.estado, c.liberada_en into estado_real, marca
  from public.capsulas c
  where c.id = '95100000-0000-0000-0000-000000000001';
  if estado_real <> 'liberada' or marca is null then
    raise exception 'FALLO: la vencida no quedó liberada';
  end if;

  select count(*) into avisos
  from public.notificaciones
  where tipo = 'capsula_liberada'
    and referencia_id = '95100000-0000-0000-0000-000000000001';
  if avisos <> 2 then
    raise exception 'FALLO: se esperaban 2 avisos y hay %', avisos;
  end if;

  if exists (
    select 1 from public.capsulas c
    where id = '95100000-0000-0000-0000-000000000002' and c.estado <> 'programada'
  ) or exists (
    select 1 from public.capsulas c
    where id = '95100000-0000-0000-0000-000000000003' and c.estado <> 'borrador'
  ) or exists (
    select 1 from public.capsulas c
    where id = '95100000-0000-0000-0000-000000000004' and c.estado <> 'cancelada'
  ) then
    raise exception 'FALLO: se tocó una futura, un borrador o una cancelada';
  end if;
end $$;

-- Segunda pasada seguida: mismos conteos, sin avisos nuevos.
do $$
declare
  liberadas integer;
  avisos integer;
  marca timestamptz;
  marca_previa timestamptz;
begin
  select liberada_en into marca_previa
  from public.capsulas
  where id = '95100000-0000-0000-0000-000000000001';

  liberadas := privado.liberar_capsulas_vencidas();
  if liberadas <> 0 then
    raise exception 'FALLO: la segunda pasada liberó % (se esperaba 0)', liberadas;
  end if;

  select count(*) into avisos
  from public.notificaciones
  where tipo = 'capsula_liberada'
    and referencia_id = '95100000-0000-0000-0000-000000000001';
  if avisos <> 2 then
    raise exception 'FALLO: la segunda pasada dejó % avisos (se esperaban 2)', avisos;
  end if;

  select liberada_en into marca
  from public.capsulas
  where id = '95100000-0000-0000-0000-000000000001';
  if marca is distinct from marca_previa then
    raise exception 'FALLO: la segunda pasada cambió liberada_en';
  end if;
end $$;

-- El índice único rechaza el duplicado y ON CONFLICT no inserta otra fila.
do $$
declare avisos integer;
begin
  begin
    insert into public.notificaciones (usuario_id, canal, tipo, referencia_id, titulo, cuerpo)
    values (
      '95000000-0000-0000-0000-0000000000b1',
      'push',
      'capsula_liberada',
      '95100000-0000-0000-0000-000000000001',
      'duplicado',
      'no debe entrar'
    );
    raise exception 'FALLO: el índice permitió un aviso duplicado';
  exception when unique_violation then
    null;
  end;

  insert into public.notificaciones (usuario_id, canal, tipo, referencia_id, titulo, cuerpo)
  values (
    '95000000-0000-0000-0000-0000000000b1',
    'push',
    'capsula_liberada',
    '95100000-0000-0000-0000-000000000001',
    'duplicado',
    'no debe entrar'
  )
  on conflict do nothing;

  select count(*) into avisos
  from public.notificaciones
  where tipo = 'capsula_liberada'
    and referencia_id = '95100000-0000-0000-0000-000000000001'
    and usuario_id = '95000000-0000-0000-0000-0000000000b1';
  if avisos <> 1 then
    raise exception 'FALLO: ON CONFLICT duplicó el aviso push (hay %)', avisos;
  end if;
end $$;

-- Dos sesiones a la vez sobre otra vencida: una sola liberación y un solo aviso.
insert into public.capsulas (id, autor_id, titulo, fecha_apertura, estado) values
  ('95100000-0000-0000-0000-000000000005', '95000000-0000-0000-0000-0000000000a1', 'Concurrente', now() - interval '1 minute', 'programada');
insert into public.capsula_destinatarios (capsula_id, usuario_id) values
  ('95100000-0000-0000-0000-000000000005', '95000000-0000-0000-0000-0000000000b1');

select dblink_connect('s1', 'host=/var/run/postgresql dbname=postgres user=postgres');
select dblink_connect('s2', 'host=/var/run/postgresql dbname=postgres user=postgres');

do $$
begin
  perform dblink_send_query('s1', 'select privado.liberar_capsulas_vencidas()');
  perform dblink_send_query('s2', 'select privado.liberar_capsulas_vencidas()');
  while dblink_is_busy('s1') <> 0 or dblink_is_busy('s2') <> 0 loop
    perform pg_sleep(0.05);
  end loop;
end $$;

do $$
declare
  n1 integer;
  n2 integer;
  avisos integer;
  estado_real public.estado_capsula;
begin
  select n into n1 from dblink_get_result('s1') as t(n integer);
  select n into n2 from dblink_get_result('s2') as t(n integer);
  perform dblink_get_result('s1');
  perform dblink_get_result('s2');
  if coalesce(n1, 0) + coalesce(n2, 0) <> 1 then
    raise exception 'FALLO: las dos sesiones liberaron % + % (se esperaba 1 en total)', n1, n2;
  end if;

  select c.estado into estado_real
  from public.capsulas c
  where c.id = '95100000-0000-0000-0000-000000000005';
  if estado_real <> 'liberada' then
    raise exception 'FALLO: la concurrente quedó en %', estado_real;
  end if;

  select count(*) into avisos
  from public.notificaciones
  where tipo = 'capsula_liberada'
    and referencia_id = '95100000-0000-0000-0000-000000000005';
  if avisos <> 1 then
    raise exception 'FALLO: la ejecución concurrente dejó % avisos', avisos;
  end if;
end $$;

select dblink_disconnect('s1');
select dblink_disconnect('s2');

select 'OK liberar_capsulas_vencidas' as r;
