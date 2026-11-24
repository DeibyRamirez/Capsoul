-- Capsoul · Cápsulas vinculadas a una herencia (migración 000032).
-- U1 dueño, U2 beneficiario, U3 autor ajeno.
-- La cápsula C1 ya estaba liberada antes de vincularse; C2 sigue programada.
-- Ninguna debe verse para U2 hasta que la herencia se libere.

\set ON_ERROR_STOP 1

begin;

insert into auth.users (id, email, raw_user_meta_data, email_confirmed_at) values
  ('c0000000-0000-0000-0000-000000000001','u1@x.co','{"nombre_visible":"Uno"}', now()),
  ('c0000000-0000-0000-0000-000000000002','u2@x.co','{"nombre_visible":"Dos"}', now()),
  ('c0000000-0000-0000-0000-000000000003','u3@x.co','{"nombre_visible":"Tres"}', now())
on conflict (id) do nothing;

-- U1 crea dos cápsulas programadas, una borrador y sus recuerdos.
set role authenticated;
set request.jwt.claim.sub = 'c0000000-0000-0000-0000-000000000001';
insert into public.capsulas (id, autor_id, titulo, mensaje, fecha_apertura, estado) values
  ('ca000000-0000-0000-0000-000000000001','c0000000-0000-0000-0000-000000000001','Cápsula ya abierta','uno', now() + interval '1 day','programada'),
  ('ca000000-0000-0000-0000-000000000002','c0000000-0000-0000-0000-000000000001','Cápsula futura','dos', now() + interval '30 days','programada'),
  ('ca000000-0000-0000-0000-000000000003','c0000000-0000-0000-0000-000000000001','Borrador','tres', null,'borrador');

insert into public.elementos (
  id, propietario_id, tipo, cloudinary_public_id, cloudinary_tipo_recurso, bytes
) values
  ('ea000000-0000-0000-0000-000000000001','c0000000-0000-0000-0000-000000000001','foto','capsoul/prueba/1','image',1000),
  ('ea000000-0000-0000-0000-000000000002','c0000000-0000-0000-0000-000000000001','foto','capsoul/prueba/2','image',1000);
insert into public.capsula_elementos values
  ('ca000000-0000-0000-0000-000000000001','ea000000-0000-0000-0000-000000000001',0),
  ('ca000000-0000-0000-0000-000000000002','ea000000-0000-0000-0000-000000000002',0);

-- U3 crea una cápsula ajena.
set request.jwt.claim.sub = 'c0000000-0000-0000-0000-000000000003';
insert into public.capsulas (id, autor_id, titulo, mensaje, fecha_apertura, estado) values
  ('ca000000-0000-0000-0000-000000000004','c0000000-0000-0000-0000-000000000003','Cápsula de otro','ajena', now() + interval '2 days','programada');

-- Se simula que C1 ya venció y quedó liberada antes de vincularse.
reset role;
update public.capsulas
   set fecha_apertura = now() - interval '1 hour'
 where id = 'ca000000-0000-0000-0000-000000000001';
select privado.liberar_capsulas_vencidas();

-- U1 crea la herencia y vincula C1 y C2.
set role authenticated;
set request.jwt.claim.sub = 'c0000000-0000-0000-0000-000000000001';
insert into public.herencias (
  id, propietario_id, titulo, beneficiario_usuario_id, condicion_activacion,
  fecha_activacion, estado
) values (
  'da000000-0000-0000-0000-000000000001',
  'c0000000-0000-0000-0000-000000000001',
  'Herencia con cápsulas',
  'c0000000-0000-0000-0000-000000000002',
  'fecha',
  now() + interval '10 days',
  'activa'
);
select public.vincular_capsula_herencia(
  'da000000-0000-0000-0000-000000000001',
  'ca000000-0000-0000-0000-000000000001'
);
select public.vincular_capsula_herencia(
  'da000000-0000-0000-0000-000000000001',
  'ca000000-0000-0000-0000-000000000002'
);

-- No se puede vincular una cápsula ajena.
do $$
begin
  perform public.vincular_capsula_herencia(
    'da000000-0000-0000-0000-000000000001',
    'ca000000-0000-0000-0000-000000000004'
  );
  raise exception 'FALLO: se pudo vincular una cápsula de otro autor';
exception
  when others then
    if position('capsula_invalida' in sqlerrm) = 0 then
      raise;
    end if;
end $$;

-- Tampoco un borrador propio.
do $$
begin
  perform public.vincular_capsula_herencia(
    'da000000-0000-0000-0000-000000000001',
    'ca000000-0000-0000-0000-000000000003'
  );
  raise exception 'FALLO: se pudo vincular un borrador';
exception
  when others then
    if position('capsula_invalida' in sqlerrm) = 0 then
      raise;
    end if;
end $$;

-- U2 es destinatario por la herencia, pero no debe ver nada todavía.
set request.jwt.claim.sub = 'c0000000-0000-0000-0000-000000000002';
do $$
declare
  v_capsulas int;
  v_recibidas int;
  v_elementos int;
begin
  select count(*) into v_capsulas from public.capsulas;
  select count(*) into v_recibidas from public.capsulas_recibidas();
  select count(*) into v_elementos from public.elementos;
  if v_capsulas <> 0 or v_recibidas <> 0 or v_elementos <> 0 then
    raise exception 'FALLO: U2 ve la herencia antes de abrir (capsulas %, recibidas %, elementos %)',
      v_capsulas, v_recibidas, v_elementos;
  end if;
end $$;

-- Se libera la herencia: C2 también pasa a liberada.
reset role;
select privado.liberar_herencia('da000000-0000-0000-0000-000000000001');

do $$
declare
  v_estado text;
  v_liberada timestamptz;
begin
  select estado::text, liberada_en into v_estado, v_liberada
    from public.capsulas where id='ca000000-0000-0000-0000-000000000002';
  if v_estado <> 'liberada' or v_liberada is null then
    raise exception 'FALLO: C2 no se liberó con la herencia (estado %, liberada_en %)',
      v_estado, v_liberada;
  end if;
end $$;

-- U2 ya ve las dos cápsulas y sus recuerdos.
set role authenticated;
set request.jwt.claim.sub = 'c0000000-0000-0000-0000-000000000002';
do $$
declare
  v_capsulas int;
  v_recibidas int;
  v_elementos int;
begin
  select count(*) into v_capsulas from public.capsulas;
  select count(*) into v_recibidas from public.capsulas_recibidas();
  select count(*) into v_elementos from public.elementos;
  if v_capsulas <> 2 or v_recibidas <> 2 or v_elementos <> 2 then
    raise exception 'FALLO: U2 no ve las cápsulas tras abrir (capsulas %, recibidas %, elementos %)',
      v_capsulas, v_recibidas, v_elementos;
  end if;
end $$;

rollback;
