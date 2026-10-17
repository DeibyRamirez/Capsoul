-- Capsoul · Mi legado: confianza global, instrucciones, vínculo herencia–cápsulas,
-- metadatos, auditoría y RPC de lectura.

begin;

-- 1) Usuario: persona de confianza global e instrucciones
alter table public.usuarios
  add column if not exists persona_confianza_legado_id uuid references public.usuarios (id) on delete set null,
  add column if not exists instrucciones_legado text;

grant update (nombre_visible, foto_public_id, perfil_publico, persona_confianza_legado_id, instrucciones_legado)
  on public.usuarios to authenticated;

-- 2) Herencias: metadatos estructurados (CDT, objeto, etc.)
alter table public.herencias
  add column if not exists metadatos jsonb not null default '{}'::jsonb;

-- 3) Vínculo herencia ↔ cápsulas
create table if not exists public.herencia_capsulas (
  herencia_id uuid not null references public.herencias (id) on delete cascade,
  capsula_id  uuid not null references public.capsulas (id) on delete cascade,
  orden       smallint not null default 0,
  primary key (herencia_id, capsula_id)
);
create index if not exists herencia_capsulas_capsula_idx on public.herencia_capsulas (capsula_id);

-- 4) Auditoría append-only
create table if not exists public.herencia_eventos (
  id          uuid primary key default gen_random_uuid(),
  herencia_id uuid not null references public.herencias (id) on delete cascade,
  tipo        text not null,
  actor_id    uuid references public.usuarios (id) on delete set null,
  detalle     jsonb not null default '{}'::jsonb,
  creado_en   timestamptz not null default now()
);
create index if not exists herencia_eventos_herencia_idx on public.herencia_eventos (herencia_id, creado_en desc);

-- 5) Solicitudes legales (MVP: registro manual)
create table if not exists public.herencia_solicitudes_legal (
  id          uuid primary key default gen_random_uuid(),
  herencia_id uuid not null references public.herencias (id) on delete cascade,
  solicitante_id uuid not null references public.usuarios (id) on delete cascade,
  estado      text not null default 'pendiente' check (estado in ('pendiente', 'en_revision', 'cerrada')),
  creado_en   timestamptz not null default now()
);
create index if not exists herencia_solicitudes_legal_herencia_idx
  on public.herencia_solicitudes_legal (herencia_id);

-- 6) Confianza global al crear herencia
create or replace function privado.herencias_rellenar_confianza()
returns trigger language plpgsql set search_path = '' as $$
begin
  if new.persona_confianza_id is null then
    select u.persona_confianza_legado_id into new.persona_confianza_id
    from public.usuarios u
    where u.id = new.propietario_id;
  end if;
  return new;
end;
$$;

drop trigger if exists herencias_rellenar_confianza on public.herencias;
create trigger herencias_rellenar_confianza
  before insert on public.herencias
  for each row execute function privado.herencias_rellenar_confianza();

-- 7) Visibilidad: confianza lee contenido solo tras liberación
create or replace function privado.puede_ver_contenido_herencia(p_herencia uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.herencias h
    where h.id = p_herencia
      and (
        h.propietario_id = (select auth.uid())
        or (
          h.estado = 'liberada'
          and (
            h.beneficiario_usuario_id = (select auth.uid())
            or h.persona_confianza_id = (select auth.uid())
          )
        )
      )
  );
$$;

-- 8) Liberación sincronizada de cápsulas vinculadas
create or replace function privado.liberar_herencia(p_herencia uuid)
returns void language plpgsql volatile security definer set search_path = '' as $$
begin
  update public.herencias
     set estado = 'liberada', liberada_en = now(), verificacion_desde = null
   where id = p_herencia and estado in ('activa', 'en_verificacion');
  if found then
    update public.capsulas c
       set estado = 'liberada', liberada_en = coalesce(c.liberada_en, now())
      from public.herencia_capsulas hc
     where hc.herencia_id = p_herencia
       and hc.capsula_id = c.id
       and c.estado = 'programada';

    insert into public.notificaciones (usuario_id, correo_destino, canal, tipo, referencia_id, titulo, cuerpo)
    select h.beneficiario_usuario_id,
           case when h.beneficiario_usuario_id is null then h.beneficiario_correo end,
           case when h.beneficiario_usuario_id is null then 'correo' else 'push' end::public.canal_notificacion,
           'herencia_liberada', h.id, 'Alguien te dejó un legado en Capsoul',
           'Tienes una herencia disponible en Capsoul.'
      from public.herencias h where h.id = p_herencia
    on conflict do nothing;

    insert into public.herencia_eventos (herencia_id, tipo, actor_id, detalle)
    values (p_herencia, 'liberada', null, '{}'::jsonb);
  end if;
end;
$$;

-- 9) Registrar eventos (solo definer / triggers)
create or replace function privado.registrar_evento_herencia(
  p_herencia uuid,
  p_tipo text,
  p_detalle jsonb default '{}'::jsonb
) returns void language sql volatile security definer set search_path = '' as $$
  insert into public.herencia_eventos (herencia_id, tipo, actor_id, detalle)
  values (p_herencia, p_tipo, auth.uid(), coalesce(p_detalle, '{}'::jsonb));
$$;

create or replace function privado.trg_evento_herencia()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if tg_op = 'INSERT' then
    perform privado.registrar_evento_herencia(new.id, 'creada', jsonb_build_object('estado', new.estado));
  elsif tg_op = 'UPDATE' and old.estado is distinct from new.estado then
    perform privado.registrar_evento_herencia(new.id, 'cambio_estado', jsonb_build_object('de', old.estado, 'a', new.estado));
  end if;
  return new;
end;
$$;

drop trigger if exists herencias_evento on public.herencias;
create trigger herencias_evento
  after insert or update of estado on public.herencias
  for each row execute function privado.trg_evento_herencia();

-- 10) RPC cliente
create or replace function public.establecer_persona_confianza_legado(p_nombre_usuario text)
returns void language plpgsql volatile security definer set search_path = '' as $$
declare
  v_uid uuid;
  yo uuid := auth.uid();
begin
  if yo is null then
    raise exception 'sin_sesion';
  end if;
  select r.usuario_id into v_uid
  from public.resolver_usuario_por_arroba(p_nombre_usuario) r
  limit 1;
  if v_uid is null then
    raise exception 'usuario_no_encontrado';
  end if;
  if not privado.son_amigos(v_uid, yo) then
    raise exception 'debe_ser_amigo';
  end if;
  update public.usuarios
     set persona_confianza_legado_id = v_uid
   where id = yo;
end;
$$;

create or replace function public.quitar_persona_confianza_legado()
returns void language sql volatile security definer set search_path = '' as $$
  update public.usuarios set persona_confianza_legado_id = null where id = auth.uid();
$$;

create or replace function public.guardar_instrucciones_legado(p_texto text)
returns void language sql volatile security definer set search_path = '' as $$
  update public.usuarios set instrucciones_legado = nullif(trim(p_texto), '') where id = auth.uid();
$$;

create or replace function public.legado_resumen()
returns json language sql stable security definer set search_path = '' as $$
  select json_build_object(
    'herencias_activas', (
      select count(*)::int from public.herencias h
      where h.propietario_id = auth.uid() and h.estado in ('borrador', 'activa', 'en_verificacion')
    ),
    'tiene_instrucciones', coalesce(
      (select instrucciones_legado is not null and char_length(trim(instrucciones_legado)) > 0
       from public.usuarios u where u.id = auth.uid()),
      false
    ),
    'persona_confianza_id', (select persona_confianza_legado_id from public.usuarios u where u.id = auth.uid())
  );
$$;

create or replace function public.legado_agrupado_beneficiario()
returns table (
  beneficiario_usuario_id uuid,
  beneficiario_correo text,
  nombre_visible text,
  foto_public_id text,
  n_herencias int,
  n_capsulas int
) language sql stable security definer set search_path = '' as $$
  select
    h.beneficiario_usuario_id,
    max(h.beneficiario_correo) as beneficiario_correo,
    max(p.nombre_visible) as nombre_visible,
    max(p.foto_public_id) as foto_public_id,
    count(distinct h.id)::int as n_herencias,
    count(distinct hc.capsula_id)::int as n_capsulas
  from public.herencias h
  left join public.perfiles_visibles p on p.id = h.beneficiario_usuario_id
  left join public.herencia_capsulas hc on hc.herencia_id = h.id
  where h.propietario_id = auth.uid()
    and h.estado <> 'revocada'
  group by h.beneficiario_usuario_id, coalesce(h.beneficiario_correo, '')
  order by max(h.creado_en) desc;
$$;

create or replace function public.herencia_detalle(p_id uuid)
returns json language sql stable security definer set search_path = '' as $$
  select json_build_object(
    'herencia', row_to_json(h.*),
    'elementos', coalesce((
      select json_agg(json_build_object(
        'elemento_id', he.elemento_id,
        'orden', he.orden,
        'tipo', e.tipo
      ) order by he.orden)
      from public.herencia_elementos he
      join public.elementos e on e.id = he.elemento_id
      where he.herencia_id = h.id and privado.puede_ver_contenido_herencia(h.id)
    ), '[]'::json),
    'capsulas', coalesce((
      select json_agg(json_build_object(
        'capsula_id', hc.capsula_id,
        'orden', hc.orden,
        'titulo', c.titulo,
        'estado', c.estado
      ) order by hc.orden)
      from public.herencia_capsulas hc
      join public.capsulas c on c.id = hc.capsula_id
      where hc.herencia_id = h.id
        and (c.autor_id = auth.uid() or privado.puede_ver_capsula(c.id))
    ), '[]'::json)
  )
  from public.herencias h
  where h.id = p_id
    and (
      h.propietario_id = auth.uid()
      or h.persona_confianza_id = auth.uid()
      or (h.estado = 'liberada' and h.beneficiario_usuario_id = auth.uid())
    );
$$;

create or replace function public.vincular_capsula_herencia(p_herencia uuid, p_capsula uuid)
returns void language plpgsql volatile security definer set search_path = '' as $$
declare
  v_benef uuid;
  v_prop uuid;
begin
  if not privado.herencia_editable_por_mi(p_herencia) then
    raise exception 'herencia_no_editable';
  end if;
  select h.propietario_id, h.beneficiario_usuario_id into v_prop, v_benef
  from public.herencias h where h.id = p_herencia;
  if not exists (
    select 1 from public.capsulas c
    where c.id = p_capsula and c.autor_id = v_prop
  ) then
    raise exception 'capsula_invalida';
  end if;
  if v_benef is not null and not exists (
    select 1 from public.capsula_destinatarios d
    where d.capsula_id = p_capsula and d.usuario_id = v_benef
  ) then
    insert into public.capsula_destinatarios (capsula_id, usuario_id)
    values (p_capsula, v_benef);
  end if;
  insert into public.herencia_capsulas (herencia_id, capsula_id)
  values (p_herencia, p_capsula)
  on conflict do nothing;
  perform privado.registrar_evento_herencia(p_herencia, 'capsula_vinculada', jsonb_build_object('capsula_id', p_capsula));
end;
$$;

create or replace function public.solicitar_respaldo_legal_herencia(p_herencia uuid)
returns void language plpgsql volatile security definer set search_path = '' as $$
begin
  if not exists (
    select 1 from public.herencias h
    where h.id = p_herencia and h.propietario_id = auth.uid()
  ) then
    raise exception 'sin_permiso';
  end if;
  insert into public.herencia_solicitudes_legal (herencia_id, solicitante_id)
  values (p_herencia, auth.uid());
  perform privado.registrar_evento_herencia(p_herencia, 'solicitud_legal', '{}'::jsonb);
end;
$$;

-- 11) RLS nuevas tablas
alter table public.herencia_capsulas enable row level security;
alter table public.herencia_eventos enable row level security;
alter table public.herencia_solicitudes_legal enable row level security;

create policy herencia_capsulas_leer on public.herencia_capsulas for select to authenticated
  using (
    exists (select 1 from public.herencias h where h.id = herencia_id and (
      h.propietario_id = auth.uid()
      or h.persona_confianza_id = auth.uid()
      or (h.estado = 'liberada' and h.beneficiario_usuario_id = auth.uid())
    ))
  );
create policy herencia_capsulas_crear on public.herencia_capsulas for insert to authenticated
  with check (privado.herencia_editable_por_mi(herencia_id));
create policy herencia_capsulas_eliminar on public.herencia_capsulas for delete to authenticated
  using (privado.herencia_editable_por_mi(herencia_id));

create policy herencia_eventos_leer on public.herencia_eventos for select to authenticated
  using (
    exists (select 1 from public.herencias h where h.id = herencia_id and (
      h.propietario_id = auth.uid()
      or h.persona_confianza_id = auth.uid()
      or (h.estado = 'liberada' and h.beneficiario_usuario_id = auth.uid())
    ))
  );

create policy herencia_solicitudes_legal_leer on public.herencia_solicitudes_legal for select to authenticated
  using (solicitante_id = auth.uid());
create policy herencia_solicitudes_legal_crear on public.herencia_solicitudes_legal for insert to authenticated
  with check (
    solicitante_id = auth.uid()
    and exists (select 1 from public.herencias h where h.id = herencia_id and h.propietario_id = auth.uid())
  );

grant select, insert, delete on public.herencia_capsulas to authenticated;
grant select on public.herencia_eventos to authenticated;
grant select, insert on public.herencia_solicitudes_legal to authenticated;

revoke all on function public.establecer_persona_confianza_legado(text),
  public.quitar_persona_confianza_legado(),
  public.guardar_instrucciones_legado(text),
  public.legado_resumen(),
  public.legado_agrupado_beneficiario(),
  public.herencia_detalle(uuid),
  public.vincular_capsula_herencia(uuid, uuid),
  public.solicitar_respaldo_legal_herencia(uuid)
  from public, anon;
grant execute on function public.establecer_persona_confianza_legado(text),
  public.quitar_persona_confianza_legado(),
  public.guardar_instrucciones_legado(text),
  public.legado_resumen(),
  public.legado_agrupado_beneficiario(),
  public.herencia_detalle(uuid),
  public.vincular_capsula_herencia(uuid, uuid),
  public.solicitar_respaldo_legal_herencia(uuid)
  to authenticated;

commit;
