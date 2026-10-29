-- Capsoul · Aviso leído de una cápsula compartida (migración 000017).
\set ON_ERROR_STOP 1

insert into auth.users (id, email, raw_user_meta_data, email_confirmed_at) values
  ('97000000-0000-0000-0000-0000000000a1', 'aviso-autor@capsoul.app', '{"nombre_visible":"AutorAviso"}', now()),
  ('97000000-0000-0000-0000-0000000000b1', 'aviso-amigo@capsoul.app', '{"nombre_visible":"AmigoAviso"}', now()),
  ('97000000-0000-0000-0000-0000000000c1', 'aviso-extra@capsoul.app', '{"nombre_visible":"ExtraAviso"}', now())
on conflict do nothing;

insert into public.capsulas (id, autor_id, titulo, fecha_apertura, estado, liberada_en) values
  (
    '97100000-0000-0000-0000-000000000001',
    '97000000-0000-0000-0000-0000000000a1',
    'Para el amigo',
    now() - interval '1 day',
    'liberada',
    now() - interval '1 hour'
  ),
  (
    '97100000-0000-0000-0000-000000000002',
    '97000000-0000-0000-0000-0000000000a1',
    'Todavía cerrada',
    now() + interval '3 days',
    'programada',
    null
  ),
  (
    '97100000-0000-0000-0000-000000000003',
    '97000000-0000-0000-0000-0000000000a1',
    'También para mí',
    now() - interval '2 days',
    'liberada',
    now() - interval '2 hours'
  );

insert into public.capsula_destinatarios (capsula_id, usuario_id) values
  ('97100000-0000-0000-0000-000000000001', '97000000-0000-0000-0000-0000000000b1'),
  ('97100000-0000-0000-0000-000000000002', '97000000-0000-0000-0000-0000000000b1'),
  ('97100000-0000-0000-0000-000000000003', '97000000-0000-0000-0000-0000000000a1'),
  ('97100000-0000-0000-0000-000000000003', '97000000-0000-0000-0000-0000000000b1');

-- El cliente no puede escribir leida_en a mano.
set role authenticated;
select set_config('request.jwt.claim.sub', '97000000-0000-0000-0000-0000000000b1', false);

do $$
begin
  begin
    update public.capsula_destinatarios
       set leida_en = now()
     where usuario_id = '97000000-0000-0000-0000-0000000000b1';
    raise exception 'FALLO: el cliente escribió leida_en';
  exception when insufficient_privilege then
    null;
  end;
end $$;

do $$
declare n integer;
begin
  select count(*) into n
  from public.capsula_destinatarios d
  join public.capsulas c on c.id = d.capsula_id
  where d.usuario_id = '97000000-0000-0000-0000-0000000000b1'
    and c.autor_id <> '97000000-0000-0000-0000-0000000000b1'
    and c.estado = 'liberada'
    and d.leida_en is null;
  if n <> 2 then
    raise exception 'FALLO: el amigo debía tener 2 avisos sin leer y tiene %', n;
  end if;
end $$;

select public.marcar_aviso_capsula_leido('97100000-0000-0000-0000-000000000001');

do $$
declare marca timestamptz;
begin
  select leida_en into marca
  from public.capsula_destinatarios
  where capsula_id = '97100000-0000-0000-0000-000000000001'
    and usuario_id = '97000000-0000-0000-0000-0000000000b1';
  if marca is null then
    raise exception 'FALLO: ver el aviso no marcó leida_en';
  end if;
end $$;

-- Una programada no se marca, aunque el amigo sea destinatario.
select public.marcar_aviso_capsula_leido('97100000-0000-0000-0000-000000000002');

do $$
declare marca timestamptz;
begin
  select leida_en into marca
  from public.capsula_destinatarios
  where capsula_id = '97100000-0000-0000-0000-000000000002'
    and usuario_id = '97000000-0000-0000-0000-0000000000b1';
  if marca is not null then
    raise exception 'FALLO: se marcó un aviso de una cápsula que no está liberada';
  end if;
end $$;

-- La segunda llamada no mueve la marca.
do $$
declare
  antes timestamptz;
  despues timestamptz;
begin
  select leida_en into antes
  from public.capsula_destinatarios
  where capsula_id = '97100000-0000-0000-0000-000000000001'
    and usuario_id = '97000000-0000-0000-0000-0000000000b1';
  perform public.marcar_aviso_capsula_leido('97100000-0000-0000-0000-000000000001');
  select leida_en into despues
  from public.capsula_destinatarios
  where capsula_id = '97100000-0000-0000-0000-000000000001'
    and usuario_id = '97000000-0000-0000-0000-0000000000b1';
  if antes is distinct from despues then
    raise exception 'FALLO: marcar otra vez cambió leida_en';
  end if;
end $$;

reset role;
set role authenticated;
select set_config('request.jwt.claim.sub', '97000000-0000-0000-0000-0000000000c1', false);
select public.marcar_aviso_capsula_leido('97100000-0000-0000-0000-000000000003');

reset role;
set role authenticated;
select set_config('request.jwt.claim.sub', '97000000-0000-0000-0000-0000000000a1', false);
select public.marcar_aviso_capsula_leido('97100000-0000-0000-0000-000000000003');

reset role;

do $$
declare marca_amigo timestamptz;
declare marca_autor timestamptz;
begin
  select leida_en into marca_amigo
  from public.capsula_destinatarios
  where capsula_id = '97100000-0000-0000-0000-000000000003'
    and usuario_id = '97000000-0000-0000-0000-0000000000b1';
  select leida_en into marca_autor
  from public.capsula_destinatarios
  where capsula_id = '97100000-0000-0000-0000-000000000003'
    and usuario_id = '97000000-0000-0000-0000-0000000000a1';
  if marca_amigo is not null then
    raise exception 'FALLO: un extraño marcó el aviso del amigo';
  end if;
  if marca_autor is not null then
    raise exception 'FALLO: el autor marcó como aviso una cápsula propia';
  end if;
end $$;

select 'OK avisos capsulas' as r;
