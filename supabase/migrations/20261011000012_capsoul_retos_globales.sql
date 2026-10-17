-- Capsoul · Retos globales de producto (catálogo en public.retos + progreso en reto_participantes)

-- 1. Retirar modelo social (entregas diarias)
drop policy if exists reto_entregas_leer on public.reto_entregas;
drop policy if exists reto_entregas_crear on public.reto_entregas;
drop policy if exists reto_entregas_eliminar on public.reto_entregas;
drop table if exists public.reto_entregas cascade;

delete from public.reto_participantes;
delete from public.retos;

-- 2. Catálogo global en public.retos
alter table public.retos alter column creador_id drop not null;
alter table public.retos drop column if exists frecuencia;
alter table public.retos drop column if exists fecha_inicio;
alter table public.retos drop column if exists fecha_fin;

alter table public.retos
  add column if not exists slug text,
  add column if not exists orden smallint not null default 0,
  add column if not exists activo boolean not null default true,
  add column if not exists pasos jsonb not null default '[]'::jsonb,
  add column if not exists criterio_clave text,
  add column if not exists criterio_parametros jsonb not null default '{}'::jsonb,
  add column if not exists actualizado_en timestamptz not null default now();

comment on table public.retos is
  'Catálogo global de retos de producto (creador_id null). Progreso por usuario en reto_participantes.';

-- 3. Progreso por usuario
alter table public.reto_participantes
  add column if not exists completado_en timestamptz,
  add column if not exists elemento_id uuid references public.elementos (id) on delete set null,
  add column if not exists capsula_id uuid references public.capsulas (id) on delete set null;

create index if not exists retos_catalogo_activo_idx
  on public.retos (orden)
  where activo and creador_id is null;

create unique index if not exists retos_slug_unico_idx
  on public.retos (slug)
  where slug is not null;

-- 4. Visibilidad de elementos sin entregas de retos sociales
create or replace function privado.puede_ver_elemento(p_elemento uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select privado.es_mi_elemento(p_elemento)
      or exists (select 1 from public.capsula_elementos ce where ce.elemento_id = p_elemento and privado.puede_ver_capsula(ce.capsula_id))
      or exists (select 1 from public.momento_elementos me where me.elemento_id = p_elemento and privado.puede_ver_momento(me.momento_id))
      or exists (select 1 from public.herencia_elementos he where he.elemento_id = p_elemento and privado.puede_ver_contenido_herencia(he.herencia_id));
$$;

create or replace function privado.participa_en_reto(p_reto uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.retos r
    where r.id = p_reto and r.activo and r.creador_id is null
  );
$$;

-- 5. Motor de criterios
create or replace function privado.cumple_criterio_reto(
  p_usuario uuid,
  p_clave text,
  p_params jsonb
) returns boolean
language plpgsql stable security definer set search_path = public as $$
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
    when 'primer_momento' then
      return exists (
        select 1 from public.momentos m where m.autor_id = p_usuario
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
    when 'recuerdos_cantidad' then
      v_minimo := coalesce((p_params->>'minimo')::int, 1);
      return (
        select count(*)::int >= v_minimo
        from public.elementos e where e.propietario_id = p_usuario
      );
    when 'herencia_borrador' then
      return exists (
        select 1 from public.herencias h
        where h.propietario_id = p_usuario and h.estado <> 'revocada'
      );
    else
      return false;
  end case;
end;
$$;

create or replace function privado.evaluar_retos_globales(p_usuario uuid)
returns void
language plpgsql security definer set search_path = public as $$
begin
  if p_usuario is null then
    return;
  end if;
  insert into public.reto_participantes (reto_id, usuario_id, estado, unido_en, completado_en)
  select r.id, p_usuario, 'completado', now(), now()
  from public.retos r
  where r.activo and r.creador_id is null
    and privado.cumple_criterio_reto(p_usuario, r.criterio_clave, r.criterio_parametros)
    and not exists (
      select 1 from public.reto_participantes rp
      where rp.reto_id = r.id and rp.usuario_id = p_usuario and rp.estado = 'completado'
    )
  on conflict (reto_id, usuario_id) do update
    set estado = 'completado',
        completado_en = coalesce(public.reto_participantes.completado_en, excluded.completado_en),
        unido_en = coalesce(public.reto_participantes.unido_en, excluded.unido_en)
  where public.reto_participantes.estado <> 'completado';
end;
$$;

create or replace function privado.trg_evaluar_retos_elementos()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  perform privado.evaluar_retos_globales(new.propietario_id);
  return new;
end;
$$;

create or replace function privado.trg_evaluar_retos_capsulas()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  perform privado.evaluar_retos_globales(new.autor_id);
  return new;
end;
$$;

create or replace function privado.trg_evaluar_retos_momentos()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  perform privado.evaluar_retos_globales(new.autor_id);
  return new;
end;
$$;

create or replace function privado.trg_evaluar_retos_amistades()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.estado = 'aceptada' then
    perform privado.evaluar_retos_globales(new.solicitante_id);
    perform privado.evaluar_retos_globales(new.receptor_id);
  end if;
  return new;
end;
$$;

create or replace function privado.trg_evaluar_retos_usuarios()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.nombre_usuario is distinct from old.nombre_usuario and new.nombre_usuario is not null then
    perform privado.evaluar_retos_globales(new.id);
  end if;
  return new;
end;
$$;

create or replace function privado.trg_evaluar_retos_herencias()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  perform privado.evaluar_retos_globales(new.propietario_id);
  return new;
end;
$$;

drop trigger if exists evaluar_retos_tras_elemento on public.elementos;
create trigger evaluar_retos_tras_elemento
  after insert on public.elementos
  for each row execute function privado.trg_evaluar_retos_elementos();

drop trigger if exists evaluar_retos_tras_capsula on public.capsulas;
create trigger evaluar_retos_tras_capsula
  after insert or update on public.capsulas
  for each row execute function privado.trg_evaluar_retos_capsulas();

drop trigger if exists evaluar_retos_tras_momento on public.momentos;
create trigger evaluar_retos_tras_momento
  after insert on public.momentos
  for each row execute function privado.trg_evaluar_retos_momentos();

drop trigger if exists evaluar_retos_tras_amistad on public.amistades;
create trigger evaluar_retos_tras_amistad
  after insert or update on public.amistades
  for each row execute function privado.trg_evaluar_retos_amistades();

drop trigger if exists evaluar_retos_tras_usuario on public.usuarios;
create trigger evaluar_retos_tras_usuario
  after update on public.usuarios
  for each row execute function privado.trg_evaluar_retos_usuarios();

drop trigger if exists evaluar_retos_tras_herencia on public.herencias;
create trigger evaluar_retos_tras_herencia
  after insert on public.herencias
  for each row execute function privado.trg_evaluar_retos_herencias();

-- 6. API de lectura para la app
create or replace function public.listar_retos_globales()
returns table (
  id uuid,
  slug text,
  titulo text,
  descripcion text,
  pasos jsonb,
  orden smallint,
  criterio_clave text,
  completado boolean,
  completado_en timestamptz
)
language sql stable security definer set search_path = public as $$
  select
    r.id,
    r.slug,
    r.titulo,
    r.descripcion,
    r.pasos,
    r.orden,
    r.criterio_clave,
    (rp.estado = 'completado') as completado,
    rp.completado_en
  from public.retos r
  left join public.reto_participantes rp
    on rp.reto_id = r.id
   and rp.usuario_id = (select auth.uid())
   and rp.estado = 'completado'
  where r.activo and r.creador_id is null
  order by r.orden, r.titulo;
$$;

create or replace function public.contar_retos_pendientes()
returns int
language sql stable security definer set search_path = public as $$
  select count(*)::int
  from public.retos r
  where r.activo and r.creador_id is null
    and not exists (
      select 1 from public.reto_participantes rp
      where rp.reto_id = r.id
        and rp.usuario_id = (select auth.uid())
        and rp.estado = 'completado'
    );
$$;

-- 7. RLS
drop policy if exists retos_leer on public.retos;
drop policy if exists retos_crear on public.retos;
drop policy if exists retos_editar on public.retos;
drop policy if exists retos_eliminar on public.retos;

create policy retos_catalogo_leer on public.retos for select to authenticated
  using (activo and creador_id is null);

drop policy if exists reto_participantes_leer on public.reto_participantes;
drop policy if exists reto_participantes_invitar on public.reto_participantes;
drop policy if exists reto_participantes_responder on public.reto_participantes;
drop policy if exists reto_participantes_salir on public.reto_participantes;

create policy reto_participantes_progreso_leer on public.reto_participantes
  for select to authenticated
  using (usuario_id = (select auth.uid()));

revoke insert, update, delete on public.retos from authenticated;
revoke insert, update, delete on public.reto_participantes from authenticated;

grant execute on function public.listar_retos_globales() to authenticated;
grant execute on function public.contar_retos_pendientes() to authenticated;

-- 8. Seed del catálogo (~20 retos)
insert into public.retos (creador_id, titulo, descripcion, slug, orden, pasos, criterio_clave, criterio_parametros)
values
  (null, 'Crea tu primera cápsula', 'Programa un mensaje para el futuro.', 'primer_capsula',
   1, '["Ve a Cápsulas","Toca crear","Elige recuerdos y fecha"]'::jsonb, 'primer_capsula', '{}'),
  (null, 'Comparte tu mejora', 'Elige un nombre @ para que tus amigos te encuentren.', 'nombre_usuario',
   2, '["Abre Perfil","Configura tu @"]'::jsonb, 'nombre_usuario', '{}'),
  (null, 'Haz un amigo', 'Conecta con alguien de confianza en Capsoul.', 'primer_amigo',
   3, '["Abre Amigos","Acepta o envía una solicitud"]'::jsonb, 'primer_amigo', '{}'),
  (null, 'Crea un recuerdo con música', 'La música y los recuerdos combinan muy bien.', 'foto_con_musica',
   4, '["Guarda una foto","Añade una canción al guardar"]'::jsonb, 'recuerdo_foto_con_musica', '{}'),
  (null, '¿Cómo te sientes hoy?', 'Captura un momento en un Momento.', 'primer_momento',
   5, '["Abre Momentos","Crea uno nuevo"]'::jsonb, 'primer_momento', '{}'),
  (null, 'Escribe una nota', 'Deja tus palabras en el banco de recuerdos.', 'recuerdo_nota',
   6, '["Toca +","Elige Escribir"]'::jsonb, 'recuerdo_nota', '{}'),
  (null, 'Graba un audio', 'Tu voz también es un recuerdo.', 'recuerdo_audio',
   7, '["Toca +","Graba audio"]'::jsonb, 'recuerdo_audio', '{}'),
  (null, 'Graba un video', 'Guarda un clip de tus mejores momentos.', 'recuerdo_video',
   8, '["Toca +","Graba video"]'::jsonb, 'recuerdo_video', '{}'),
  (null, 'Toma una foto', 'Un recuerdo fotogénico en tu banco.', 'recuerdo_foto',
   9, '["Toca +","Toma una foto"]'::jsonb, 'recuerdo_foto', '{}'),
  (null, 'Guarda una canción', 'Añade música al banco de recuerdos.', 'recuerdo_musica',
   10, '["Toca +","Busca música"]'::jsonb, 'recuerdo_musica', '{}'),
  (null, 'Programa una cápsula', 'Sella contenido para una fecha futura.', 'capsula_programada',
   11, '["Crea una cápsula","Pon fecha de apertura"]'::jsonb, 'capsula_programada', '{}'),
  (null, 'Piensa en tu legado', 'Empieza una herencia digital.', 'herencia_borrador',
   12, '["Abre Legado","Crea una herencia"]'::jsonb, 'herencia_borrador', '{}'),
  (null, 'Cinco recuerdos', 'Llena tu banco con al menos cinco piezas.', 'recuerdos_cinco',
   13, '["Guarda fotos, notas o audios"]'::jsonb, 'recuerdos_cantidad', '{"minimo":5}'),
  (null, 'Diez recuerdos', 'Sigue construyendo tu historia.', 'recuerdos_diez',
   14, '["Sigue guardando recuerdos"]'::jsonb, 'recuerdos_cantidad', '{"minimo":10}'),
  (null, 'Tres tipos distintos', 'Prueba foto, nota y audio (mín. 3 recuerdos).', 'recuerdos_tres',
   15, '["Varía los formatos"]'::jsonb, 'recuerdos_cantidad', '{"minimo":3}');

alter table public.retos alter column slug set not null;
alter table public.retos alter column criterio_clave set not null;
