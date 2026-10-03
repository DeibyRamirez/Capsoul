-- =====================================================================
-- Capsoul · Límites de medios, máximo de elementos por cápsula y cuota
-- Versión: BORRADOR 1.0 · 2026-10-03 · Autor: Flutter Dev (límites aprobados por el PO)
-- Estado: pendiente de aprobación del PO. NO aplicada.
-- Requiere: 20261002000001_capsoul_modelo_inicial.sql (v1.3) aplicada.
--
-- Límites (los mismos de LimitesMedios en la app y de la Edge Function firmar-subida;
-- 1 MB = 1 048 576 bytes):
--   * foto  : JPEG, lado mayor <= 1600 px, calidad 75, tope 2 MB          (2 097 152 bytes)
--   * video : 720p, <= 60 s (+1 s de holgura del codificador), ~2,5 Mbps,
--             tope 20 MB                                                  (20 971 520 bytes)
--   * audio : AAC mono 64 kbps, <= 5 min (+1 s), ~2,4 MB, tope 3 MB        (3 145 728 bytes)
--   * nota  : 1..5000 caracteres (char_length)
--   * máximo 10 elementos por cápsula (trigger)
--   * cuota de 200 MB por usuario sumando elementos.bytes (trigger)  (209 715 200 bytes)
-- Errores propios (SQLSTATE) que traduce la app:
--   * CAP01 cuota de medios excedida
--   * CAP02 máximo de elementos por cápsula
-- Las restricciones check fallan con 23514 (check_violation).
-- =====================================================================

begin;

-- ---------------------------------------------------------------------
-- 1. Restricciones check en elementos
-- ---------------------------------------------------------------------
-- Si el proyecto ya tuviera filas que no cumplen, cambiar "add constraint ... check (...)"
-- por "... not valid" y validarlas después de limpiar los datos.

-- Tipo coherente con el tipo de recurso de Cloudinary (el audio es 'video' en Cloudinary).
alter table public.elementos add constraint elementos_tipo_recurso_coherente check (
  (tipo = 'texto' and cloudinary_tipo_recurso is null)
  or (tipo = 'foto' and cloudinary_tipo_recurso = 'image')
  or (tipo in ('video', 'audio') and cloudinary_tipo_recurso = 'video')
);

-- Todo medio declara su tamaño (lo necesita la cuota) y no supera el tope de su tipo.
alter table public.elementos add constraint elementos_bytes_limite check (
  case tipo
    when 'texto' then true
    when 'foto'  then bytes is not null and bytes <= 2097152
    when 'video' then bytes is not null and bytes <= 20971520
    when 'audio' then bytes is not null and bytes <= 3145728
  end
);

-- Video y audio declaran su duración y no superan el máximo (1 s de holgura).
alter table public.elementos add constraint elementos_duracion_limite check (
  case tipo
    when 'video' then duracion_segundos is not null and duracion_segundos > 0 and duracion_segundos <= 61
    when 'audio' then duracion_segundos is not null and duracion_segundos > 0 and duracion_segundos <= 301
    else duracion_segundos is null
  end
);

-- Fotos: lado mayor <= 1600 px cuando Cloudinary informa las dimensiones.
alter table public.elementos add constraint elementos_dimensiones_foto check (
  tipo <> 'foto' or ((ancho is null or ancho <= 1600) and (alto is null or alto <= 1600))
);

-- Notas: de 1 a 5000 caracteres.
alter table public.elementos add constraint elementos_texto_limite check (
  tipo <> 'texto' or char_length(contenido_texto) between 1 and 5000
);

-- ---------------------------------------------------------------------
-- 2. Cuota de 200 MB por usuario
-- ---------------------------------------------------------------------
-- Bytes ocupados por los medios de un usuario (SECURITY DEFINER: suma también filas que
-- RLS no le mostraría, aunque hoy elementos_leer ya incluye las propias).
create or replace function privado.bytes_usados(p_usuario uuid)
returns bigint language sql stable security definer set search_path = '' as $$
  select coalesce(sum(e.bytes), 0)::bigint
  from public.elementos e
  where e.propietario_id = p_usuario;
$$;

create or replace function privado.validar_cuota_medios()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  limite constant bigint := 209715200; -- 200 MB
  usados bigint;
begin
  if new.bytes is null then
    return new;
  end if;
  -- Serializa las subidas concurrentes del mismo usuario.
  perform pg_advisory_xact_lock(hashtextextended('capsoul_cuota:' || new.propietario_id::text, 0));
  select coalesce(sum(e.bytes), 0) into usados
  from public.elementos e
  where e.propietario_id = new.propietario_id
    and (tg_op = 'INSERT' or e.id <> new.id);
  if usados + new.bytes > limite then
    raise exception 'Cuota de medios excedida: % de % bytes', usados + new.bytes, limite
      using errcode = 'CAP01';
  end if;
  return new;
end $$;

create trigger elementos_validar_cuota
  before insert or update of bytes, propietario_id on public.elementos
  for each row execute function privado.validar_cuota_medios();

-- RPC para la app y para la Edge Function firmar-subida (con el JWT del usuario):
-- cuánto ocupa y cuál es el límite. Solo devuelve datos de quien llama.
create or replace function public.mi_uso_medios()
returns table (bytes_usados bigint, bytes_limite bigint)
language sql stable security definer set search_path = '' as $$
  select privado.bytes_usados((select auth.uid())), 209715200::bigint
  where (select auth.uid()) is not null;
$$;

-- ---------------------------------------------------------------------
-- 3. Máximo 10 elementos por cápsula
-- ---------------------------------------------------------------------
create or replace function privado.validar_maximo_elementos_capsula()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  maximo constant integer := 10;
  actuales integer;
begin
  -- Bloquea la cápsula para que dos inserciones simultáneas no pasen el máximo.
  perform 1 from public.capsulas c where c.id = new.capsula_id for update;
  select count(*) into actuales
  from public.capsula_elementos ce
  where ce.capsula_id = new.capsula_id;
  if actuales >= maximo then
    raise exception 'Una cápsula admite como máximo % elementos', maximo
      using errcode = 'CAP02';
  end if;
  return new;
end $$;

create trigger capsula_elementos_validar_maximo
  before insert on public.capsula_elementos
  for each row execute function privado.validar_maximo_elementos_capsula();

-- ---------------------------------------------------------------------
-- 4. Permisos (mismo criterio que la sección 9 de la migración 000001)
-- ---------------------------------------------------------------------
-- Las funciones de trigger no necesitan EXECUTE para el cliente; bytes_usados solo la usan
-- funciones definer. Nadie del cliente ejecuta funciones nuevas de privado.
revoke all on function privado.bytes_usados(uuid), privado.validar_cuota_medios(),
  privado.validar_maximo_elementos_capsula() from public, anon, authenticated;

revoke all on function public.mi_uso_medios() from public, anon;
grant execute on function public.mi_uso_medios() to authenticated;

commit;
