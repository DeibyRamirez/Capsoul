-- =====================================================================
-- Capsoul · Recuerdos independientes, momentos con portada y arreglo de RLS de lectura
-- Versión: 1.0 · 2026-10-03 · Autor: Flutter Dev (plan B aprobado por el PO el 2026-10-03)
-- Estado: aprobada por el PO; se aplica con la Management API y se registra en
--         supabase_migrations.schema_migrations.
-- Requiere: 20261002000001 (v1.3) y 20261003000003 aplicadas.
--
-- 1. Arreglo del error 42501 al crear filas con RETURNING (insert().select() de PostgREST):
--    las políticas SELECT llamaban a funciones STABLE que vuelven a leer la tabla y no ven la
--    fila recién insertada. Ahora comparan primero la columna del dueño (que sí ve la fila nueva
--    y además evita la llamada a la función en el caso más común).
-- 2. elementos (Recuerdos): titulo opcional (<= 120) y fecha_recuerdo (por defecto la fecha
--    de creado_en) para filtrar el banco de recuerdos.
-- 3. CAP03: no se puede borrar un recuerdo que está en una cápsula programada o liberada
--    (salvo cuando se borra la cuenta completa).
-- 4. momentos: titulo obligatorio (1..80) y portada_elemento_id (foto o video del autor que
--    pertenezca al momento); si la portada sale del momento, queda en null.
-- Errores propios (SQLSTATE): CAP03 recuerdo en cápsula; CAP04 portada inválida.
-- =====================================================================

begin;

-- ---------------------------------------------------------------------
-- 1. Políticas de lectura (mismo alcance, primero la columna del dueño)
-- ---------------------------------------------------------------------
drop policy elementos_leer on public.elementos;
create policy elementos_leer on public.elementos for select to authenticated
  using (propietario_id = (select auth.uid()) or privado.puede_ver_elemento(id));

drop policy capsulas_leer on public.capsulas;
create policy capsulas_leer on public.capsulas for select to authenticated
  using (autor_id = (select auth.uid()) or privado.puede_ver_capsula(id));

drop policy momentos_leer on public.momentos;
create policy momentos_leer on public.momentos for select to authenticated
  using (autor_id = (select auth.uid()) or privado.puede_ver_momento(id));

-- ---------------------------------------------------------------------
-- 2. elementos: título y fecha del recuerdo
-- ---------------------------------------------------------------------
alter table public.elementos add column titulo text;
alter table public.elementos add constraint elementos_titulo_limite check (
  titulo is null or (char_length(titulo) <= 120 and btrim(titulo) <> '')
);

alter table public.elementos add column fecha_recuerdo date;
update public.elementos set fecha_recuerdo = (creado_en at time zone 'utc')::date
  where fecha_recuerdo is null;
alter table public.elementos alter column fecha_recuerdo set not null;
alter table public.elementos add constraint elementos_fecha_recuerdo_minima check (
  fecha_recuerdo >= date '1900-01-01'
);
create index elementos_propietario_fecha_idx
  on public.elementos (propietario_id, fecha_recuerdo desc, creado_en desc);

-- La app envía la fecha local; si no llega, se usa la fecha (UTC) de creado_en.
-- (NOT NULL se comprueba después de los triggers BEFORE.)
create or replace function privado.completar_fecha_recuerdo()
returns trigger language plpgsql set search_path = '' as $$
begin
  if new.fecha_recuerdo is null then
    new.fecha_recuerdo := (coalesce(new.creado_en, now()) at time zone 'utc')::date;
  end if;
  return new;
end $$;

create trigger elementos_completar_fecha
  before insert or update of fecha_recuerdo on public.elementos
  for each row execute function privado.completar_fecha_recuerdo();

-- ---------------------------------------------------------------------
-- 3. CAP03: no borrar recuerdos que están en cápsulas programadas o liberadas
-- ---------------------------------------------------------------------
create or replace function privado.impedir_borrar_elemento_en_capsula()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  -- Al borrar la cuenta (cascada desde usuarios) el perfil ya no existe: se permite.
  if not exists (select 1 from public.usuarios u where u.id = old.propietario_id) then
    return old;
  end if;
  if exists (
    select 1
    from public.capsula_elementos ce
    join public.capsulas c on c.id = ce.capsula_id
    where ce.elemento_id = old.id and c.estado in ('programada', 'liberada')
  ) then
    raise exception 'El recuerdo está en una cápsula programada o liberada'
      using errcode = 'CAP03';
  end if;
  return old;
end $$;

create trigger elementos_impedir_borrar_en_capsula
  before delete on public.elementos
  for each row execute function privado.impedir_borrar_elemento_en_capsula();

-- ---------------------------------------------------------------------
-- 4. momentos: título y portada
-- ---------------------------------------------------------------------
alter table public.momentos add column titulo text;
update public.momentos
  set titulo = coalesce(nullif(left(btrim(texto), 80), ''), 'Momento')
  where titulo is null;
alter table public.momentos alter column titulo set not null;
alter table public.momentos add constraint momentos_titulo_limite check (
  char_length(titulo) <= 80 and btrim(titulo) <> ''
);

alter table public.momentos add column portada_elemento_id uuid
  references public.elementos (id) on delete set null;
create index momentos_portada_idx on public.momentos (portada_elemento_id)
  where portada_elemento_id is not null;

-- La portada es una foto o un video del autor que ya está en momento_elementos
-- (flujo de la app: crear momento -> agregar elementos -> fijar portada).
create or replace function privado.validar_portada_momento()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if new.portada_elemento_id is null then
    return new;
  end if;
  if not exists (
    select 1
    from public.momento_elementos me
    join public.elementos e on e.id = me.elemento_id
    where me.momento_id = new.id
      and me.elemento_id = new.portada_elemento_id
      and e.propietario_id = new.autor_id
      and e.tipo in ('foto', 'video')
  ) then
    raise exception 'La portada debe ser una foto o un video del momento'
      using errcode = 'CAP04';
  end if;
  return new;
end $$;

create trigger momentos_validar_portada
  before insert or update of portada_elemento_id on public.momentos
  for each row execute function privado.validar_portada_momento();

-- Si la portada sale del momento, se quita.
create or replace function privado.quitar_portada_momento()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  update public.momentos m
    set portada_elemento_id = null
    where m.id = old.momento_id and m.portada_elemento_id = old.elemento_id;
  return old;
end $$;

create trigger momento_elementos_quitar_portada
  after delete on public.momento_elementos
  for each row execute function privado.quitar_portada_momento();

-- ---------------------------------------------------------------------
-- 5. Permisos (criterio de la 000001: nadie del cliente ejecuta funciones nuevas de privado)
-- ---------------------------------------------------------------------
revoke all on function privado.completar_fecha_recuerdo(),
  privado.impedir_borrar_elemento_en_capsula(),
  privado.validar_portada_momento(),
  privado.quitar_portada_momento() from public, anon, authenticated;

commit;
