-- Capsoul · El autor puede apuntarse como destinatario (migración 000016).
\set ON_ERROR_STOP 1

insert into auth.users (id, email, raw_user_meta_data, email_confirmed_at) values
  ('96000000-0000-0000-0000-0000000000a1', 'autor@capsoul.app', '{"nombre_visible":"Autor"}', now()),
  ('96000000-0000-0000-0000-0000000000b1', 'amigo@capsoul.app', '{"nombre_visible":"Amigo"}', now()),
  ('96000000-0000-0000-0000-0000000000c1', 'extra@capsoul.app', '{"nombre_visible":"Extra"}', now())
on conflict do nothing;

insert into public.amistades (solicitante_id, receptor_id, estado, respondido_en)
values (
  '96000000-0000-0000-0000-0000000000a1',
  '96000000-0000-0000-0000-0000000000b1',
  'aceptada',
  now()
);

set role authenticated;
select set_config('request.jwt.claim.sub', '96000000-0000-0000-0000-0000000000a1', false);

insert into public.capsulas (id, autor_id, titulo, fecha_apertura, estado)
values (
  '96100000-0000-0000-0000-000000000001',
  '96000000-0000-0000-0000-0000000000a1',
  'Para mí mismo',
  now() + interval '2 days',
  'borrador'
);

insert into public.capsula_destinatarios (capsula_id, usuario_id)
values (
  '96100000-0000-0000-0000-000000000001',
  '96000000-0000-0000-0000-0000000000a1'
);

insert into public.capsula_destinatarios (capsula_id, usuario_id)
values (
  '96100000-0000-0000-0000-000000000001',
  '96000000-0000-0000-0000-0000000000b1'
);

do $$
begin
  begin
    insert into public.capsula_destinatarios (capsula_id, usuario_id)
    values (
      '96100000-0000-0000-0000-000000000001',
      '96000000-0000-0000-0000-0000000000c1'
    );
    raise exception 'FALLO: se insertó un destinatario que no es amigo';
  exception when insufficient_privilege then
    null;
  end;
end $$;

do $$
declare n integer;
begin
  select count(*) into n
  from public.capsula_destinatarios
  where capsula_id = '96100000-0000-0000-0000-000000000001';
  if n <> 2 then
    raise exception 'FALLO: se esperaban autor y amigo, hay % destinatarios', n;
  end if;
end $$;

reset role;
select 'OK autor destinatario' as r;
