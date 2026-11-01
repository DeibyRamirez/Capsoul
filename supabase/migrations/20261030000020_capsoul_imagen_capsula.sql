-- Capsoul - Imagen local de la capsula (2026-10-30).
-- La imagen es un asset propio de la app (assets/imagenes_capsula/); aqui solo
-- se guarda su clave estable (capsula_01 .. capsula_16). Nullable: las capsulas
-- existentes quedan en null y la app muestra la imagen por defecto.
-- No edita migraciones ya aplicadas. No se aplica en el remoto sin el PO.

begin;

alter table public.capsulas
  add column if not exists imagen_clave text;

alter table public.capsulas
  drop constraint if exists capsulas_imagen_clave_formato;
alter table public.capsulas
  add constraint capsulas_imagen_clave_formato
  check (imagen_clave is null or imagen_clave ~ '^capsula_[0-9]{2}$');

comment on column public.capsulas.imagen_clave is
  'Clave de la imagen local de la app (catalogo ImagenCapsula). Null = imagen por defecto.';

-- GRANT UPDATE por columnas (20261007000007): permitir cambiar la imagen al editar.
grant update (imagen_clave) on public.capsulas to authenticated;

-- El destinatario ve la imagen en su lista (no revela contenido de la capsula).
-- Cambia el tipo de retorno: hay que recrear la funcion y sus permisos.
drop function if exists public.capsulas_recibidas();
create function public.capsulas_recibidas()
returns table (capsula_id uuid, autor_id uuid, autor_nombre text, titulo text,
               fecha_apertura timestamptz, estado public.estado_capsula,
               liberada_en timestamptz, imagen_clave text)
language sql stable security definer set search_path = '' as $$
  select c.id, c.autor_id, u.nombre_visible,
         case when c.estado = 'liberada' then c.titulo end,
         c.fecha_apertura, c.estado, c.liberada_en, c.imagen_clave
  from public.capsula_destinatarios d
  join public.capsulas c on c.id = d.capsula_id
  join public.usuarios u on u.id = c.autor_id
  where d.usuario_id = (select auth.uid())
    and c.estado in ('programada', 'liberada')
  order by c.fecha_apertura;
$$;

revoke all on function public.capsulas_recibidas() from public, anon;
grant execute on function public.capsulas_recibidas() to authenticated;

commit;