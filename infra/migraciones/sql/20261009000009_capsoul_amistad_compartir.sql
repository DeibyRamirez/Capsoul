-- Capsoul · Compartir cápsulas entre amigos + invitaciones por enlace (2026-10-12)

-- Destinatario puede ver metadatos de cápsula programada (contenido sigue vía elementos/RLS).
create or replace function privado.puede_ver_capsula(p_capsula uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.capsulas c
    where c.id = p_capsula
      and (
        c.autor_id = (select auth.uid())
        or (
          c.estado in ('programada', 'liberada')
          and exists (
            select 1 from public.capsula_destinatarios d
            where d.capsula_id = c.id and d.usuario_id = (select auth.uid())
          )
        )
      )
  );
$$;

drop policy if exists capsula_destinatarios_crear on public.capsula_destinatarios;
create policy capsula_destinatarios_crear on public.capsula_destinatarios
  for insert to authenticated
  with check (
    privado.capsula_editable_por_mi(capsula_id)
    and usuario_id is not null
    and privado.son_amigos(
      (select c.autor_id from public.capsulas c where c.id = capsula_id),
      usuario_id
    )
  );

-- Invitaciones a amistad (enlace capsoul://amistad/{token})
create table public.invitaciones_amistad (
  id               uuid primary key default gen_random_uuid(),
  token            text not null unique,
  solicitante_id   uuid not null references public.usuarios (id) on delete cascade,
  expira_en        timestamptz not null,
  usos_restantes   smallint not null default 1 check (usos_restantes >= 0),
  creado_en        timestamptz not null default now()
);
create index invitaciones_amistad_solicitante_idx
  on public.invitaciones_amistad (solicitante_id, creado_en desc);

alter table public.invitaciones_amistad enable row level security;
-- Sin políticas para authenticated: solo RPC security definer.

create or replace function public.crear_invitacion_amistad(p_dias_validez int default 7)
returns text
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  yo uuid := auth.uid();
  tok text;
begin
  if yo is null then
    raise exception 'sin_sesion';
  end if;
  tok := replace(gen_random_uuid()::text, '-', '') || replace(gen_random_uuid()::text, '-', '');
  insert into public.invitaciones_amistad (token, solicitante_id, expira_en)
  values (tok, yo, now() + make_interval(days => greatest(p_dias_validez, 1)));
  return tok;
end;
$$;

create or replace function public.aceptar_invitacion_amistad(p_token text)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  inv public.invitaciones_amistad;
  yo uuid := auth.uid();
  a uuid;
  b uuid;
begin
  if yo is null then
    raise exception 'sin_sesion';
  end if;
  select * into inv
  from public.invitaciones_amistad
  where token = btrim(p_token)
    and expira_en > now()
    and usos_restantes > 0;
  if not found then
    raise exception 'invitacion_invalida';
  end if;
  if inv.solicitante_id = yo then
    raise exception 'no_autoinvitacion';
  end if;
  a := least(inv.solicitante_id, yo);
  b := greatest(inv.solicitante_id, yo);
  if exists (
    select 1 from public.amistades am
    where least(am.solicitante_id, am.receptor_id) = a
      and greatest(am.solicitante_id, am.receptor_id) = b
      and am.estado = 'aceptada'
  ) then
    update public.invitaciones_amistad
       set usos_restantes = greatest(usos_restantes - 1, 0)
     where id = inv.id;
    return;
  end if;
  if exists (
    select 1 from public.amistades am
    where least(am.solicitante_id, am.receptor_id) = a
      and greatest(am.solicitante_id, am.receptor_id) = b
  ) then
    update public.amistades am
       set estado = 'aceptada', respondido_en = coalesce(am.respondido_en, now())
     where least(am.solicitante_id, am.receptor_id) = a
       and greatest(am.solicitante_id, am.receptor_id) = b;
  else
    insert into public.amistades (solicitante_id, receptor_id, estado, respondido_en)
    values (inv.solicitante_id, yo, 'aceptada', now());
  end if;
  update public.invitaciones_amistad
     set usos_restantes = greatest(usos_restantes - 1, 0)
   where id = inv.id;
end;
$$;

create or replace function public.mis_amigos()
returns table (usuario_id uuid, nombre_visible text)
language sql
stable
security definer
set search_path = ''
as $$
  select p.id, p.nombre_visible
  from public.perfiles_visibles p
  where p.id <> (select auth.uid())
    and privado.son_amigos(p.id, (select auth.uid()))
  order by p.nombre_visible;
$$;

create or replace function public.mis_solicitudes_amistad_pendientes()
returns table (
  amistad_id uuid,
  solicitante_id uuid,
  solicitante_nombre text,
  creado_en timestamptz
)
language sql
stable
security definer
set search_path = ''
as $$
  select am.id, am.solicitante_id, u.nombre_visible, am.creado_en
  from public.amistades am
  join public.usuarios u on u.id = am.solicitante_id
  where am.receptor_id = (select auth.uid())
    and am.estado = 'pendiente'
  order by am.creado_en desc;
$$;

revoke all on function public.crear_invitacion_amistad(int),
  public.aceptar_invitacion_amistad(text),
  public.mis_amigos(),
  public.mis_solicitudes_amistad_pendientes()
  from public, anon;
grant execute on function public.crear_invitacion_amistad(int),
  public.aceptar_invitacion_amistad(text),
  public.mis_amigos(),
  public.mis_solicitudes_amistad_pendientes()
  to authenticated;

revoke all on public.invitaciones_amistad from public, anon, authenticated;
