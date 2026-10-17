-- Capsoul · Prueba de privado.liberar_capsulas_vencidas() (DEV-98 C3)
\set ON_ERROR_STOP 1

insert into auth.users (id, email, raw_user_meta_data, email_confirmed_at) values
 ('00000000-0000-0000-0000-00000000010a','lib-a@x.co','{"nombre_visible":"LibA"}', now()),
 ('00000000-0000-0000-0000-00000000010b','lib-b@x.co','{"nombre_visible":"LibB"}', now())
 on conflict do nothing;

set role authenticated;
set request.jwt.claim.sub = '00000000-0000-0000-0000-00000000010a';
insert into public.elementos (id, propietario_id, tipo, cloudinary_public_id, cloudinary_tipo_recurso)
values ('11000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-00000000010a','foto','capsoul/lib/1','image')
on conflict do nothing;
insert into public.capsulas (id, autor_id, titulo, mensaje, fecha_apertura, estado)
values (
  '21000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-00000000010a',
  'Lib test',
  'hola',
  now() + interval '2 minutes',
  'programada'
) on conflict do nothing;
insert into public.capsula_elementos values ('21000000-0000-0000-0000-000000000001','11000000-0000-0000-0000-000000000001',0)
on conflict do nothing;
insert into public.capsula_destinatarios (capsula_id, usuario_id)
values ('21000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-00000000010b')
on conflict do nothing;
reset role;

update public.capsulas
set fecha_apertura = now() - interval '1 minute'
where id = '21000000-0000-0000-0000-000000000001';

select privado.liberar_capsulas_vencidas() as liberadas;

select estado, liberada_en is not null as tiene_liberada_en
from public.capsulas
where id = '21000000-0000-0000-0000-000000000001';

select count(*) as notificaciones_push
from public.notificaciones
where tipo = 'capsula_liberada'
  and referencia_id = '21000000-0000-0000-0000-000000000001'
  and canal = 'push';

set role authenticated;
set request.jwt.claim.sub = '00000000-0000-0000-0000-00000000010b';
select titulo, estado from public.capsulas_recibidas();
select count(*) as elementos_visibles from public.elementos;
reset role;
