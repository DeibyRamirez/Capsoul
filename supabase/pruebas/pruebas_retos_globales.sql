-- Capsoul · Catálogo de retos globales (000012).
\set ON_ERROR_STOP 1

do $$
declare n integer;
begin
  select count(*) into n from public.retos where slug = 'primer_capsula';
  if n <> 1 then
    raise exception 'FALLO: falta el reto primer_capsula (hay %)', n;
  end if;
  select count(*) into n
  from public.retos
  where activo and creador_id is null;
  if n <> 25 then
    raise exception 'FALLO: se esperaban 25 retos activos, hay %', n;
  end if;
end $$;

insert into auth.users (id, email, raw_user_meta_data, email_confirmed_at) values
  ('00000000-0000-0000-0000-0000000095aa', 'retos@capsoul.app', '{"nombre_visible":"Retos"}', now())
on conflict do nothing;

set role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-0000000095aa', false);

do $$
declare n integer;
begin
  select count(*) into n from public.listar_retos_globales();
  if n < 1 then
    raise exception 'FALLO: listar_retos_globales no devolvió el catálogo';
  end if;
  n := public.contar_retos_pendientes();
  if n < 1 then
    raise exception 'FALLO: contar_retos_pendientes quedó en 0';
  end if;
end $$;

reset role;

-- Fixtures para validar los criterios nuevos (usuario 95aa)
insert into public.elementos (id, propietario_id, tipo, contenido_texto)
  values ('95000000-0000-0000-0000-00000000e101', '00000000-0000-0000-0000-0000000095aa', 'texto', 'nota reto');
insert into public.elementos (id, propietario_id, tipo, cloudinary_public_id, cloudinary_tipo_recurso, bytes, ancho, alto)
  values ('95000000-0000-0000-0000-00000000e102', '00000000-0000-0000-0000-0000000095aa', 'foto', 'reto/foto', 'image', 100, 100, 100);
insert into public.elementos (id, propietario_id, tipo, cloudinary_public_id, cloudinary_tipo_recurso, bytes, duracion_segundos)
  values ('95000000-0000-0000-0000-00000000e103', '00000000-0000-0000-0000-0000000095aa', 'audio', 'reto/audio', 'video', 100, 10);
insert into public.elementos (
  id, propietario_id, tipo, cloudinary_public_id, cloudinary_tipo_recurso, bytes, ancho, alto,
  musica_proveedor, musica_id_externo, musica_titulo, musica_artista, musica_url_completa
) values (
  '95000000-0000-0000-0000-00000000e104', '00000000-0000-0000-0000-0000000095aa', 'foto',
  'reto/foto-musica', 'image', 100, 100, 100,
  'spotify', 'track-reto', 'Canción', 'Artista', 'https://open.spotify.com/track/reto'
);
insert into public.elementos (propietario_id, tipo, contenido_texto)
  select '00000000-0000-0000-0000-0000000095aa', 'texto', 'recuerdo ' || i
  from generate_series(1, 25) i;

insert into public.capsulas (id, autor_id, titulo, estado) values
  ('95000000-0000-0000-0000-00000000c101', '00000000-0000-0000-0000-0000000095aa', 'Cápsula 1', 'borrador'),
  ('95000000-0000-0000-0000-00000000c102', '00000000-0000-0000-0000-0000000095aa', 'Cápsula 2', 'borrador'),
  ('95000000-0000-0000-0000-00000000c103', '00000000-0000-0000-0000-0000000095aa', 'Cápsula 3', 'borrador');

insert into public.capsula_elementos (capsula_id, elemento_id, orden) values
  ('95000000-0000-0000-0000-00000000c101', '95000000-0000-0000-0000-00000000e101', 1),
  ('95000000-0000-0000-0000-00000000c101', '95000000-0000-0000-0000-00000000e102', 2),
  ('95000000-0000-0000-0000-00000000c101', '95000000-0000-0000-0000-00000000e103', 3);

insert into public.capsula_destinatarios (capsula_id, correo_externo)
  values ('95000000-0000-0000-0000-00000000c102', 'destino-reto@example.com');

insert into public.momentos (id, autor_id, titulo) values
  ('95000000-0000-0000-0000-00000000d101', '00000000-0000-0000-0000-0000000095aa', 'Momento 1'),
  ('95000000-0000-0000-0000-00000000d102', '00000000-0000-0000-0000-0000000095aa', 'Momento 2'),
  ('95000000-0000-0000-0000-00000000d103', '00000000-0000-0000-0000-0000000095aa', 'Momento 3');

insert into public.momento_elementos (momento_id, elemento_id, orden) values
  ('95000000-0000-0000-0000-00000000d101', '95000000-0000-0000-0000-00000000e101', 1),
  ('95000000-0000-0000-0000-00000000d101', '95000000-0000-0000-0000-00000000e102', 2),
  ('95000000-0000-0000-0000-00000000d101', '95000000-0000-0000-0000-00000000e103', 3);

insert into public.herencias (
  id, propietario_id, titulo, beneficiario_correo, condicion_activacion, fecha_activacion, estado
) values (
  '95000000-0000-0000-0000-00000000a101', '00000000-0000-0000-0000-0000000095aa',
  'Herencia reto', 'heredero-reto@example.com', 'fecha', now() + interval '1 day', 'borrador'
);
insert into public.herencia_capsulas (herencia_id, capsula_id)
  values ('95000000-0000-0000-0000-00000000a101', '95000000-0000-0000-0000-00000000c103');

update public.usuarios
set foto_public_id = 'reto/avatar',
    persona_confianza_legado_id = '00000000-0000-0000-0000-0000000095aa'
where id = '00000000-0000-0000-0000-0000000095aa';

do $$
declare n integer;
begin
  select count(*) into n
  from public.reto_participantes rp
  join public.retos r on r.id = rp.reto_id
  where rp.usuario_id = '00000000-0000-0000-0000-0000000095aa'
    and rp.estado = 'completado'
    and r.slug in (
      'persona_confianza',
      'tres_capsulas',
      'capsula_tres_recuerdos',
      'tres_momentos',
      'momento_tres_recuerdos',
      'herencia_con_capsula',
      'comparte_capsula',
      'recuerdo_con_musica',
      'perfil_con_foto',
      'veinticinco_recuerdos'
    );
  if n <> 10 then
    raise exception 'FALLO: se completaron % de los 10 retos nuevos', n;
  end if;
end $$;

select 'OK retos globales' as r;
