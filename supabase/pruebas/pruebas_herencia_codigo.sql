-- Capsoul · Código de acceso de la persona de confianza (migraciones 000030 y 000031).
-- U1 propietario, U2 beneficiario, U3 persona de confianza, U4 otra amiga.
-- Ejecutar como postgres sobre una base con las migraciones aplicadas.

\set ON_ERROR_STOP 1

begin;

insert into auth.users (id, email, raw_user_meta_data, email_confirmed_at) values
  ('b0000000-0000-0000-0000-000000000001','u1@x.co','{"nombre_visible":"Uno"}', now()),
  ('b0000000-0000-0000-0000-000000000002','u2@x.co','{"nombre_visible":"Dos"}', now()),
  ('b0000000-0000-0000-0000-000000000003','u3@x.co','{"nombre_visible":"Tres"}', now()),
  ('b0000000-0000-0000-0000-000000000004','u4@x.co','{"nombre_visible":"Cuatro"}', now())
on conflict (id) do nothing;

-- Amistades de U1 con U2, U3 y U4
set role authenticated;
set request.jwt.claim.sub = 'b0000000-0000-0000-0000-000000000001';
insert into public.amistades (solicitante_id, receptor_id) values
  ('b0000000-0000-0000-0000-000000000001','b0000000-0000-0000-0000-000000000002'),
  ('b0000000-0000-0000-0000-000000000001','b0000000-0000-0000-0000-000000000003'),
  ('b0000000-0000-0000-0000-000000000001','b0000000-0000-0000-0000-000000000004');

set request.jwt.claim.sub = 'b0000000-0000-0000-0000-000000000002';
update public.amistades set estado = 'aceptada'
 where solicitante_id = 'b0000000-0000-0000-0000-000000000001'
   and receptor_id = 'b0000000-0000-0000-0000-000000000002';

set request.jwt.claim.sub = 'b0000000-0000-0000-0000-000000000003';
update public.amistades set estado = 'aceptada'
 where solicitante_id = 'b0000000-0000-0000-0000-000000000001'
   and receptor_id = 'b0000000-0000-0000-0000-000000000003';

set request.jwt.claim.sub = 'b0000000-0000-0000-0000-000000000004';
update public.amistades set estado = 'aceptada'
 where solicitante_id = 'b0000000-0000-0000-0000-000000000001'
   and receptor_id = 'b0000000-0000-0000-0000-000000000004';

-- U1 crea la herencia, un recuerdo y lo vincula.
set request.jwt.claim.sub = 'b0000000-0000-0000-0000-000000000001';
insert into public.herencias (
  id, propietario_id, titulo, beneficiario_usuario_id, persona_confianza_id,
  condicion_activacion, fecha_activacion, estado, metadatos
) values (
  'd0000000-0000-0000-0000-000000000001',
  'b0000000-0000-0000-0000-000000000001',
  'Reloj de familia',
  'b0000000-0000-0000-0000-000000000002',
  'b0000000-0000-0000-0000-000000000003',
  'fecha',
  now() + interval '10 days',
  'activa',
  '{"tipo_activo":"Reloj","titular":"Uno","valor_aproximado":1500000,"instrucciones":"Entregar a Dos"}'::jsonb
);

insert into public.elementos (
  id, propietario_id, tipo, cloudinary_public_id, cloudinary_tipo_recurso, bytes
) values (
  'e0000000-0000-0000-0000-000000000001',
  'b0000000-0000-0000-0000-000000000001',
  'foto', 'capsoul/u1/reloj', 'image', 1000
);
insert into public.herencia_elementos values (
  'd0000000-0000-0000-0000-000000000001',
  'e0000000-0000-0000-0000-000000000001',
  0
);

-- U3 ve la herencia en su lista, pero sin contenido ni acceso.
set request.jwt.claim.sub = 'b0000000-0000-0000-0000-000000000003';
do $$
declare
  v_lista int;
  v_detalle json;
begin
  select count(*) into v_lista from public.herencias_a_mi_cuidado();
  if v_lista <> 1 then
    raise exception 'FALLO: U3 debería ver 1 legado a su cuidado, ve %', v_lista;
  end if;

  v_detalle := public.herencia_detalle('d0000000-0000-0000-0000-000000000001');
  if v_detalle is null then
    raise exception 'FALLO: U3 no puede leer el detalle básico';
  end if;
  if (v_detalle->'acceso'->>'activo')::boolean then
    raise exception 'FALLO: U3 no debería tener acceso antes de liberar';
  end if;
  if (v_detalle->'herencia'->'metadatos')::jsonb <> '{}'::jsonb then
    raise exception 'FALLO: U3 no debería ver metadatos sellados';
  end if;
end $$;

do $$
declare v json;
begin
  v := public.validar_codigo_herencia(
    'd0000000-0000-0000-0000-000000000001', '000000'
  );
  if v->>'codigo' <> 'sin_permiso' then
    raise exception 'FALLO: antes de liberar debía responder sin_permiso, respondió %', v;
  end if;
end $$;

-- Se libera la herencia: debe quedar el aviso de correo para U3.
reset role;
select privado.liberar_herencia('d0000000-0000-0000-0000-000000000001');

do $$
declare v int;
begin
  select count(*) into v
    from public.notificaciones
   where tipo = 'herencia_codigo_acceso'
     and referencia_id = 'd0000000-0000-0000-0000-000000000001'
     and usuario_id = 'b0000000-0000-0000-0000-000000000003'
     and correo_destino = 'u3@x.co'
     and canal = 'correo';
  if v <> 1 then
    raise exception 'FALLO: debía existir 1 aviso de código para U3, hay %', v;
  end if;
end $$;

-- La Edge Function (service_role) genera el código. Aquí se simula con postgres.
select codigo, expira_en
  from public.generar_codigo_herencia(
    'd0000000-0000-0000-0000-000000000001',
    'b0000000-0000-0000-0000-000000000003'
  ) \gset

-- psql no interpola variables dentro de bloques DO; se pasa por un setting.
select set_config('prueba.codigo', :'codigo', false);

-- U3 intenta un código incorrecto, luego el correcto.
set role authenticated;
set request.jwt.claim.sub = 'b0000000-0000-0000-0000-000000000003';

do $$
declare
  v json;
  v_malo text;
begin
  v_malo := case
    when current_setting('prueba.codigo') = '000000' then '000001'
    else '000000'
  end;
  v := public.validar_codigo_herencia(
    'd0000000-0000-0000-0000-000000000001', v_malo
  );
  if v->>'codigo' <> 'codigo_incorrecto' then
    raise exception 'FALLO: el código incorrecto debía responder codigo_incorrecto, respondió %', v;
  end if;
  if (v->>'intentos_restantes')::int <> 4 then
    raise exception 'FALLO: debían quedar 4 intentos, quedan %', v->>'intentos_restantes';
  end if;
end $$;

do $$
declare v json;
begin
  v := public.validar_codigo_herencia(
    'd0000000-0000-0000-0000-000000000001', current_setting('prueba.codigo')
  );
  if not (v->>'ok')::boolean then
    raise exception 'FALLO: el código correcto no abrió el legado: %', v;
  end if;
end $$;

do $$
declare v int;
  v_detalle json;
begin
  select count(*) into v from public.elementos;
  if v <> 1 then
    raise exception 'FALLO: U3 debía ver 1 recuerdo tras desbloquear, ve %', v;
  end if;

  v_detalle := public.herencia_detalle('d0000000-0000-0000-0000-000000000001');
  if not (v_detalle->'acceso'->>'activo')::boolean then
    raise exception 'FALLO: el detalle debía marcar el acceso activo';
  end if;
  if (v_detalle->'herencia'->'metadatos')::jsonb = '{}'::jsonb then
    raise exception 'FALLO: el detalle debía mostrar los metadatos tras desbloquear';
  end if;
end $$;

do $$
declare v json;
begin
  v := public.validar_codigo_herencia(
    'd0000000-0000-0000-0000-000000000001', current_setting('prueba.codigo')
  );
  if v->>'codigo' <> 'codigo_no_vigente' then
    raise exception 'FALLO: el código era de un solo uso, respondió %', v;
  end if;
end $$;

-- Reenvío: justo después del aviso inicial hay que esperar; después se permite.
do $$
declare v json;
begin
  v := public.solicitar_codigo_herencia('d0000000-0000-0000-0000-000000000001');
  if v->>'codigo' <> 'espera_reenvio' then
    raise exception 'FALLO: el reenvío inmediato debía esperar, respondió %', v;
  end if;
end $$;

reset role;
update public.notificaciones
   set creado_en = now() - interval '2 minutes'
 where tipo = 'herencia_codigo_acceso'
   and referencia_id = 'd0000000-0000-0000-0000-000000000001'
   and usuario_id = 'b0000000-0000-0000-0000-000000000003';

set role authenticated;
set request.jwt.claim.sub = 'b0000000-0000-0000-0000-000000000003';
do $$
declare v json;
begin
  v := public.solicitar_codigo_herencia('d0000000-0000-0000-0000-000000000001');
  if not (v->>'ok')::boolean then
    raise exception 'FALLO: el reenvío debía quedar pendiente, respondió %', v;
  end if;
end $$;

rollback;
