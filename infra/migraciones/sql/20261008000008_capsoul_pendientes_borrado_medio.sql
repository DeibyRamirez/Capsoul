-- Capsoul · Cola de borrado Cloudinary tras DELETE en elementos (DEV-98 C4)

create table if not exists privado.pendientes_borrado_medio (
  id                       uuid primary key default gen_random_uuid(),
  cloudinary_public_id     text not null,
  cloudinary_tipo_recurso  text not null
    check (cloudinary_tipo_recurso in ('image', 'video', 'raw')),
  creado_en                timestamptz not null default now(),
  procesado_en             timestamptz,
  ultimo_error             text
);

create index if not exists pendientes_borrado_pendientes_idx
  on privado.pendientes_borrado_medio (creado_en)
  where procesado_en is null;

create or replace function privado.encolar_borrado_medio()
returns trigger
language plpgsql
security definer
set search_path = public, privado
as $$
begin
  if old.cloudinary_public_id is not null and old.cloudinary_tipo_recurso is not null then
    insert into privado.pendientes_borrado_medio (
      cloudinary_public_id,
      cloudinary_tipo_recurso
    ) values (old.cloudinary_public_id, old.cloudinary_tipo_recurso);
  end if;
  return old;
end;
$$;

drop trigger if exists elementos_encolar_borrado on public.elementos;
create trigger elementos_encolar_borrado
  after delete on public.elementos
  for each row execute function privado.encolar_borrado_medio();

revoke all on privado.pendientes_borrado_medio from public, anon, authenticated;
grant select, update on privado.pendientes_borrado_medio to service_role;
