-- Diario · catálogo ampliado a 25 entradas y validaciones nuevas.
--
-- El catálogo anterior tenía 15 filas. Este bloque:
--   * corrige "Tres tipos distintos" para que valide tipos reales;
--   * agrega criterios para cápsulas, momentos, legado y perfil;
--   * añade triggers en las tablas puente;
--   * suma 10 entradas nuevas (orden 16–25).

-- 1. Corregir la validación de "Tres tipos distintos"
update public.retos
set descripcion = 'Prueba al menos tres formatos distintos.',
    pasos = '["Guarda una foto","Escribe una nota","Graba un audio"]'::jsonb,
    criterio_clave = 'recuerdos_tipos',
    criterio_parametros = '{"minimo":3}'::jsonb
where slug = 'recuerdos_tres';

-- 2. Ampliar el motor de criterios
create or replace function privado.cumple_criterio_reto(
  p_usuario uuid,
  p_clave text,
  p_params jsonb
) returns boolean
language plpgsql stable security definer set search_path = '' as $$
declare
  v_minimo int;
begin
  case p_clave
    when 'recuerdo_foto' then
      return exists (
        select 1 from public.elementos e
        where e.propietario_id = p_usuario and e.tipo = 'foto'
      );
    when 'recuerdo_foto_con_musica' then
      return exists (
        select 1 from public.elementos e
        where e.propietario_id = p_usuario and e.tipo = 'foto'
          and e.musica_id_externo is not null
      );
    when 'recuerdo_video' then
      return exists (
        select 1 from public.elementos e
        where e.propietario_id = p_usuario and e.tipo = 'video'
      );
    when 'recuerdo_audio' then
      return exists (
        select 1 from public.elementos e
        where e.propietario_id = p_usuario and e.tipo = 'audio'
      );
    when 'recuerdo_nota' then
      return exists (
        select 1 from public.elementos e
        where e.propietario_id = p_usuario and e.tipo = 'texto'
      );
    when 'recuerdo_musica' then
      return exists (
        select 1 from public.elementos e
        where e.propietario_id = p_usuario and e.tipo = 'musica'
      );
    when 'recuerdo_con_musica' then
      return exists (
        select 1 from public.elementos e
        where e.propietario_id = p_usuario
          and e.musica_id_externo is not null
      );
    when 'primer_capsula' then
      return exists (
        select 1 from public.capsulas c
        where c.autor_id = p_usuario and c.estado <> 'cancelada'
      );
    when 'capsula_programada' then
      return exists (
        select 1 from public.capsulas c
        where c.autor_id = p_usuario and c.estado = 'programada'
          and c.fecha_apertura is not null and c.fecha_apertura > now()
      );
    when 'capsulas_cantidad' then
      v_minimo := coalesce((p_params->>'minimo')::int, 1);
      return (
        select count(*)::int >= v_minimo
        from public.capsulas c
        where c.autor_id = p_usuario and c.estado <> 'cancelada'
      );
    when 'capsula_elementos_cantidad' then
      v_minimo := coalesce((p_params->>'minimo')::int, 1);
      return exists (
        select 1
        from public.capsulas c
        join public.capsula_elementos ce on ce.capsula_id = c.id
        where c.autor_id = p_usuario and c.estado <> 'cancelada'
        group by c.id
        having count(*) >= v_minimo
      );
    when 'capsula_compartida' then
      return exists (
        select 1
        from public.capsulas c
        join public.capsula_destinatarios cd on cd.capsula_id = c.id
        where c.autor_id = p_usuario
          and (cd.usuario_id is null or cd.usuario_id <> c.autor_id)
      );
    when 'primer_momento' then
      return exists (
        select 1 from public.momentos m where m.autor_id = p_usuario
      );
    when 'momentos_cantidad' then
      v_minimo := coalesce((p_params->>'minimo')::int, 1);
      return (
        select count(*)::int >= v_minimo
        from public.momentos m where m.autor_id = p_usuario
      );
    when 'momento_elementos_cantidad' then
      v_minimo := coalesce((p_params->>'minimo')::int, 1);
      return exists (
        select 1
        from public.momentos m
        join public.momento_elementos me on me.momento_id = m.id
        where m.autor_id = p_usuario
        group by m.id
        having count(*) >= v_minimo
      );
    when 'primer_amigo' then
      return exists (
        select 1 from public.amistades a
        where a.estado = 'aceptada'
          and (a.solicitante_id = p_usuario or a.receptor_id = p_usuario)
      );
    when 'nombre_usuario' then
      return exists (
        select 1 from public.usuarios u
        where u.id = p_usuario and u.nombre_usuario is not null
      );
    when 'perfil_con_foto' then
      return exists (
        select 1 from public.usuarios u
        where u.id = p_usuario and u.foto_public_id is not null
      );
    when 'recuerdos_cantidad' then
      v_minimo := coalesce((p_params->>'minimo')::int, 1);
      return (
        select count(*)::int >= v_minimo
        from public.elementos e where e.propietario_id = p_usuario
      );
    when 'recuerdos_tipos' then
      v_minimo := coalesce((p_params->>'minimo')::int, 1);
      return (
        select count(distinct e.tipo)::int >= v_minimo
        from public.elementos e where e.propietario_id = p_usuario
      );
    when 'herencia_borrador' then
      return exists (
        select 1 from public.herencias h
        where h.propietario_id = p_usuario and h.estado <> 'revocada'
      );
    when 'herencia_con_capsula' then
      return exists (
        select 1
        from public.herencias h
        join public.herencia_capsulas hc on hc.herencia_id = h.id
        where h.propietario_id = p_usuario and h.estado <> 'revocada'
      );
    when 'persona_confianza' then
      return exists (
        select 1 from public.usuarios u
        where u.id = p_usuario and u.persona_confianza_legado_id is not null
      );
    else
      return false;
  end case;
end;
$$;

-- 3. Evaluar también cambios de perfil (foto y persona de confianza)
create or replace function privado.trg_evaluar_retos_usuarios()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  perform privado.evaluar_retos_globales(new.id);
  return new;
end;
$$;

create or replace function privado.trg_evaluar_retos_capsula_elementos()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  v_autor uuid;
begin
  select c.autor_id into v_autor
  from public.capsulas c
  where c.id = new.capsula_id;
  perform privado.evaluar_retos_globales(v_autor);
  return new;
end;
$$;

create or replace function privado.trg_evaluar_retos_momento_elementos()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  v_autor uuid;
begin
  select m.autor_id into v_autor
  from public.momentos m
  where m.id = new.momento_id;
  perform privado.evaluar_retos_globales(v_autor);
  return new;
end;
$$;

create or replace function privado.trg_evaluar_retos_capsula_destinatarios()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  v_autor uuid;
begin
  select c.autor_id into v_autor
  from public.capsulas c
  where c.id = new.capsula_id;
  perform privado.evaluar_retos_globales(v_autor);
  return new;
end;
$$;

create or replace function privado.trg_evaluar_retos_herencia_capsulas()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  v_propietario uuid;
begin
  select h.propietario_id into v_propietario
  from public.herencias h
  where h.id = new.herencia_id;
  perform privado.evaluar_retos_globales(v_propietario);
  return new;
end;
$$;

drop trigger if exists evaluar_retos_tras_capsula_elemento on public.capsula_elementos;
create trigger evaluar_retos_tras_capsula_elemento
  after insert on public.capsula_elementos
  for each row execute function privado.trg_evaluar_retos_capsula_elementos();

drop trigger if exists evaluar_retos_tras_momento_elemento on public.momento_elementos;
create trigger evaluar_retos_tras_momento_elemento
  after insert on public.momento_elementos
  for each row execute function privado.trg_evaluar_retos_momento_elementos();

drop trigger if exists evaluar_retos_tras_capsula_destinatario on public.capsula_destinatarios;
create trigger evaluar_retos_tras_capsula_destinatario
  after insert on public.capsula_destinatarios
  for each row execute function privado.trg_evaluar_retos_capsula_destinatarios();

drop trigger if exists evaluar_retos_tras_herencia_capsula on public.herencia_capsulas;
create trigger evaluar_retos_tras_herencia_capsula
  after insert on public.herencia_capsulas
  for each row execute function privado.trg_evaluar_retos_herencia_capsulas();

-- 4. Diez entradas nuevas para completar 25
insert into public.retos (
  creador_id,
  titulo,
  descripcion,
  slug,
  orden,
  pasos,
  criterio_clave,
  criterio_parametros
)
values
  (null, 'Elige a tu persona de confianza', 'Deja tu legado en manos de alguien de confianza.', 'persona_confianza',
   16, '["Abre Mi legado","Elige una persona de confianza"]'::jsonb, 'persona_confianza', '{}'),
  (null, 'Tres cápsulas al futuro', 'Programa tres mensajes para el futuro.', 'tres_capsulas',
   17, '["Crea una cápsula","Repite hasta tener tres"]'::jsonb, 'capsulas_cantidad', '{"minimo":3}'),
  (null, 'Una cápsula con tres recuerdos', 'Sella una cápsula con al menos tres recuerdos.', 'capsula_tres_recuerdos',
   18, '["Crea una cápsula","Añade tres recuerdos"]'::jsonb, 'capsula_elementos_cantidad', '{"minimo":3}'),
  (null, 'Tres momentos', 'Organiza tu historia en tres momentos.', 'tres_momentos',
   19, '["Abre Momentos","Crea tres momentos"]'::jsonb, 'momentos_cantidad', '{"minimo":3}'),
  (null, 'Un momento con tres recuerdos', 'Reúne tres recuerdos en un mismo momento.', 'momento_tres_recuerdos',
   20, '["Crea un momento","Añade tres recuerdos"]'::jsonb, 'momento_elementos_cantidad', '{"minimo":3}'),
  (null, 'Un legado con cápsula', 'Vincula una cápsula a una herencia.', 'herencia_con_capsula',
   21, '["Abre Mi legado","Crea una herencia","Vincula una cápsula"]'::jsonb, 'herencia_con_capsula', '{}'),
  (null, 'Comparte una cápsula', 'Envía una cápsula a alguien especial.', 'comparte_capsula',
   22, '["Crea una cápsula","Añade un destinatario"]'::jsonb, 'capsula_compartida', '{}'),
  (null, 'Música para un recuerdo', 'Acompaña cualquier recuerdo con una canción.', 'recuerdo_con_musica',
   23, '["Guarda un recuerdo","Añade música"]'::jsonb, 'recuerdo_con_musica', '{}'),
  (null, 'Ponle cara a tu perfil', 'Completa tu perfil con una foto.', 'perfil_con_foto',
   24, '["Abre Perfil","Cambia tu foto"]'::jsonb, 'perfil_con_foto', '{}'),
  (null, 'Veinticinco recuerdos', 'Tu banco de recuerdos ya es una historia.', 'veinticinco_recuerdos',
   25, '["Sigue guardando recuerdos"]'::jsonb, 'recuerdos_cantidad', '{"minimo":25}');

notify pgrst, 'reload schema';
