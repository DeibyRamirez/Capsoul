-- Capsoul · Identificador @ (nombre_usuario) y solicitudes de amistad (2026-10-12)

alter table public.usuarios
  add column if not exists nombre_usuario text;

alter table public.usuarios
  drop constraint if exists usuarios_nombre_usuario_formato;

alter table public.usuarios
  add constraint usuarios_nombre_usuario_formato check (
    nombre_usuario is null
    or (
      char_length(nombre_usuario) between 3 and 30
      and nombre_usuario ~ '^[a-z0-9_]+$'
    )
  );

create unique index if not exists usuarios_nombre_usuario_unico_idx
  on public.usuarios (lower(nombre_usuario))
  where nombre_usuario is not null;

create or replace function privado.normalizar_nombre_usuario(p_texto text)
returns text
language sql
immutable
set search_path = ''
as $$
  select case
    when p_texto is null or trim(p_texto) = '' then null
    else lower(regexp_replace(trim(both '@' from trim(p_texto)), '[^a-z0-9_]', '', 'g'))
  end;
$$;

create or replace function privado.crear_perfil_usuario()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  nom_usuario text;
begin
  nom_usuario := privado.normalizar_nombre_usuario(
    new.raw_user_meta_data ->> 'nombre_usuario'
  );
  insert into public.usuarios (id, nombre_visible, correo, nombre_usuario)
  values (
    new.id,
    coalesce(nullif(trim(new.raw_user_meta_data ->> 'nombre_visible'), ''), split_part(new.email, '@', 1)),
    new.email,
    nom_usuario
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop view if exists public.perfiles_visibles;
drop function if exists privado.perfiles_visibles();

create function privado.perfiles_visibles()
returns table (
  id uuid,
  nombre_visible text,
  nombre_usuario text,
  foto_public_id text,
  perfil_publico boolean
)
language sql
stable
security definer
set search_path = ''
as $$
  select u.id, u.nombre_visible, u.nombre_usuario, u.foto_public_id, u.perfil_publico
  from public.usuarios u
  where u.id = (select auth.uid())
     or u.perfil_publico
     or privado.son_amigos(u.id, (select auth.uid()));
$$;

grant execute on function privado.perfiles_visibles() to authenticated;
create view public.perfiles_visibles with (security_invoker = true) as
  select id, nombre_visible, nombre_usuario, foto_public_id, perfil_publico
  from privado.perfiles_visibles();
revoke all on public.perfiles_visibles from public, anon;
grant select on public.perfiles_visibles to authenticated;

create or replace function public.resolver_usuario_por_arroba(p_arroba text)
returns table (
  usuario_id uuid,
  nombre_visible text,
  foto_public_id text
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  nom text := privado.normalizar_nombre_usuario(p_arroba);
  yo uuid := auth.uid();
begin
  if yo is null then
    raise exception 'sin_sesion';
  end if;
  if nom is null or char_length(nom) < 3 then
    return;
  end if;
  return query
  select u.id, u.nombre_visible, u.foto_public_id
  from public.usuarios u
  where lower(u.nombre_usuario) = nom
    and u.id <> yo
  limit 1;
end;
$$;

create or replace function public.establecer_mi_nombre_usuario(p_arroba text)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  nom text := privado.normalizar_nombre_usuario(p_arroba);
  yo uuid := auth.uid();
begin
  if yo is null then
    raise exception 'sin_sesion';
  end if;
  if nom is null or nom !~ '^[a-z0-9_]{3,30}$' then
    raise exception 'nombre_usuario_invalido';
  end if;
  if exists (
    select 1 from public.usuarios u
    where lower(u.nombre_usuario) = nom and u.id <> yo
  ) then
    raise exception 'nombre_usuario_ocupado';
  end if;
  update public.usuarios
     set nombre_usuario = nom
   where id = yo
     and nombre_usuario is null;
  if not found then
    raise exception 'nombre_usuario_ya_fijado';
  end if;
end;
$$;

create or replace function public.enviar_solicitud_amistad(p_receptor_id uuid)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  yo uuid := auth.uid();
  estado_actual public.estado_amistad;
begin
  if yo is null then
    raise exception 'sin_sesion';
  end if;
  if p_receptor_id is null or p_receptor_id = yo then
    raise exception 'receptor_invalido';
  end if;
  if not exists (select 1 from public.usuarios u where u.id = p_receptor_id) then
    raise exception 'usuario_no_existe';
  end if;
  if privado.son_amigos(yo, p_receptor_id) then
    raise exception 'ya_son_amigos';
  end if;
  select am.estado into estado_actual
  from public.amistades am
  where least(am.solicitante_id, am.receptor_id) = least(yo, p_receptor_id)
    and greatest(am.solicitante_id, am.receptor_id) = greatest(yo, p_receptor_id);
  if estado_actual = 'pendiente' then
    raise exception 'solicitud_pendiente';
  end if;
  if estado_actual is not null then
    raise exception 'solicitud_no_posible';
  end if;
  insert into public.amistades (solicitante_id, receptor_id, estado)
  values (yo, p_receptor_id, 'pendiente');
end;
$$;

drop function if exists public.mis_amigos();

create function public.mis_amigos()
returns table (usuario_id uuid, nombre_visible text, nombre_usuario text)
language sql
stable
security definer
set search_path = ''
as $$
  select p.id, p.nombre_visible, p.nombre_usuario
  from public.perfiles_visibles p
  where p.id <> (select auth.uid())
    and privado.son_amigos(p.id, (select auth.uid()))
  order by p.nombre_visible;
$$;

grant execute on function public.mis_amigos() to authenticated;

revoke all on function public.resolver_usuario_por_arroba(text),
  public.establecer_mi_nombre_usuario(text),
  public.enviar_solicitud_amistad(uuid)
  from public, anon;
grant execute on function public.resolver_usuario_por_arroba(text),
  public.establecer_mi_nombre_usuario(text),
  public.enviar_solicitud_amistad(uuid)
  to authenticated;
