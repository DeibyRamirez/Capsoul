-- Capsoul · Permisos de herencias y cápsulas vinculadas.
-- - Destinatario de cápsula por herencia (`origen_herencia_id`).
-- - No forzar cápsulas a `liberada` al activar la herencia.
-- - Contenido de medio de cápsula solo si `liberada` (fecha_apertura del cron).
-- - Beneficiario ve que llegó (RPC) sin metadatos hasta `liberada`.
-- - Avisos: herencia_asignada, herencia_por_confirmar, capsula_compartida.
-- No edita migraciones ya aplicadas.

begin;

-- ---------------------------------------------------------------------
-- 1. Destinatarios originados por una herencia
-- ---------------------------------------------------------------------
alter table public.capsula_destinatarios
  add column if not exists origen_herencia_id uuid
    references public.herencias (id) on delete cascade;

create index if not exists capsula_destinatarios_origen_herencia_idx
  on public.capsula_destinatarios (origen_herencia_id);

drop policy if exists capsula_destinatarios_crear on public.capsula_destinatarios;
create policy capsula_destinatarios_crear on public.capsula_destinatarios
  for insert to authenticated
  with check (
    origen_herencia_id is null
    and privado.capsula_editable_por_mi(capsula_id)
    and usuario_id is not null
    and (
      usuario_id = (
        select c.autor_id from public.capsulas c where c.id = capsula_id
      )
      or privado.son_amigos(
        (select c.autor_id from public.capsulas c where c.id = capsula_id),
        usuario_id
      )
    )
  );

-- ---------------------------------------------------------------------
-- 2. Editable solo mientras sigue sellada (fecha futura si aplica)
-- ---------------------------------------------------------------------
create or replace function privado.herencia_editable_por_mi(p_herencia uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.herencias h
    where h.id = p_herencia
      and h.propietario_id = (select auth.uid())
      and h.estado in ('borrador', 'activa')
      and (
        h.condicion_activacion <> 'fecha'
        or h.fecha_activacion is null
        or h.fecha_activacion > now()
      )
  );
$$;

-- ---------------------------------------------------------------------
-- 3. Contenido de medio: cápsula solo si ya está liberada
-- ---------------------------------------------------------------------
create or replace function privado.puede_ver_elemento(p_elemento uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select privado.es_mi_elemento(p_elemento)
      or exists (
        select 1
          from public.capsula_elementos ce
          join public.capsulas c on c.id = ce.capsula_id
         where ce.elemento_id = p_elemento
           and c.estado = 'liberada'
           and privado.puede_ver_capsula(ce.capsula_id)
      )
      or exists (
        select 1 from public.momento_elementos me
         where me.elemento_id = p_elemento
           and privado.puede_ver_momento(me.momento_id)
      )
      or exists (
        select 1 from public.herencia_elementos he
         where he.elemento_id = p_elemento
           and privado.puede_ver_contenido_herencia(he.herencia_id)
      );
$$;

-- ---------------------------------------------------------------------
-- 4. RLS de herencias: el cliente no lee metadatos ajenos sellados.
--    Recibidas / por confirmar van por RPC SECURITY DEFINER.
-- ---------------------------------------------------------------------
drop policy if exists herencias_leer on public.herencias;
create policy herencias_leer on public.herencias for select to authenticated
  using (
    propietario_id = (select auth.uid())
    or (
      estado = 'liberada'
      and beneficiario_usuario_id = (select auth.uid())
    )
  );

drop policy if exists herencia_capsulas_leer on public.herencia_capsulas;
create policy herencia_capsulas_leer on public.herencia_capsulas for select to authenticated
  using (
    exists (
      select 1 from public.herencias h
       where h.id = herencia_id
         and (
           h.propietario_id = (select auth.uid())
           or (
             h.estado = 'liberada'
             and h.beneficiario_usuario_id = (select auth.uid())
           )
         )
    )
  );

drop policy if exists herencia_capsulas_crear on public.herencia_capsulas;
revoke insert on public.herencia_capsulas from authenticated, anon, public;

-- ---------------------------------------------------------------------
-- 5. Sincronizar destinatarios de cápsulas con el beneficiario
-- ---------------------------------------------------------------------
create or replace function privado.sincronizar_destinatarios_herencia(p_herencia uuid)
returns void language plpgsql volatile security definer set search_path = '' as $$
declare
  v_benef uuid;
begin
  select h.beneficiario_usuario_id into v_benef
    from public.herencias h where h.id = p_herencia;
  if not found then
    return;
  end if;

  delete from public.capsula_destinatarios d
   where d.origen_herencia_id = p_herencia
     and (v_benef is null or d.usuario_id is distinct from v_benef);

  if v_benef is null then
    return;
  end if;

  insert into public.capsula_destinatarios (capsula_id, usuario_id, origen_herencia_id)
  select hc.capsula_id, v_benef, p_herencia
    from public.herencia_capsulas hc
   where hc.herencia_id = p_herencia
  on conflict (capsula_id, usuario_id) where usuario_id is not null
  do nothing;
end;
$$;

create or replace function privado.trg_herencia_capsulas_destinatarios()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if tg_op = 'DELETE' then
    delete from public.capsula_destinatarios d
     where d.capsula_id = old.capsula_id
       and d.origen_herencia_id = old.herencia_id;
    return old;
  end if;
  perform privado.sincronizar_destinatarios_herencia(new.herencia_id);
  return new;
end;
$$;

drop trigger if exists herencia_capsulas_destinatarios on public.herencia_capsulas;
create trigger herencia_capsulas_destinatarios
  after insert or delete on public.herencia_capsulas
  for each row execute function privado.trg_herencia_capsulas_destinatarios();

create or replace function privado.trg_herencias_beneficiario_destinatarios()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if tg_op = 'UPDATE'
     and old.beneficiario_usuario_id is not distinct from new.beneficiario_usuario_id then
    return new;
  end if;
  perform privado.sincronizar_destinatarios_herencia(new.id);
  return new;
end;
$$;

drop trigger if exists herencias_beneficiario_destinatarios on public.herencias;
create trigger herencias_beneficiario_destinatarios
  after insert or update of beneficiario_usuario_id on public.herencias
  for each row execute function privado.trg_herencias_beneficiario_destinatarios();

-- ---------------------------------------------------------------------
-- 6. Liberar herencia SIN abrir cápsulas (se respeta fecha_apertura)
-- ---------------------------------------------------------------------
create or replace function privado.liberar_herencia(p_herencia uuid)
returns void language plpgsql volatile security definer set search_path = '' as $$
begin
  update public.herencias
     set estado = 'liberada', liberada_en = now(), verificacion_desde = null
   where id = p_herencia and estado in ('activa', 'en_verificacion');
  if found then
    insert into public.notificaciones (usuario_id, correo_destino, canal, tipo, referencia_id, titulo, cuerpo)
    select h.beneficiario_usuario_id,
           case when h.beneficiario_usuario_id is null then h.beneficiario_correo end,
           case when h.beneficiario_usuario_id is null then 'correo' else 'push' end::public.canal_notificacion,
           'herencia_liberada', h.id, 'Tienes un legado disponible',
           'Una herencia se activó y ya puedes verla.'
      from public.herencias h where h.id = p_herencia
    on conflict do nothing;

    insert into public.herencia_eventos (herencia_id, tipo, actor_id, detalle)
    values (p_herencia, 'liberada', null, '{}'::jsonb);
  end if;
end;
$$;

-- ---------------------------------------------------------------------
-- 7. Avisos al asignar herencia y al compartir cápsula
-- ---------------------------------------------------------------------
create or replace function privado.encolar_aviso_herencia_asignada()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  v_nombre text;
begin
  if new.estado is distinct from 'activa' then
    return new;
  end if;
  if tg_op = 'UPDATE' and old.estado = 'activa' then
    return new;
  end if;

  select nullif(trim(u.nombre_visible), '') into v_nombre
    from public.usuarios u where u.id = new.propietario_id;

  if new.beneficiario_usuario_id is not null then
    insert into public.notificaciones (usuario_id, canal, tipo, referencia_id, titulo, cuerpo)
    values (
      new.beneficiario_usuario_id,
      'push',
      'herencia_asignada',
      new.id,
      'Te dejaron un legado',
      coalesce(v_nombre, 'Alguien') || ' te asignó una pequeña herencia en Capsoul.'
    )
    on conflict do nothing;
  elsif new.beneficiario_correo is not null then
    insert into public.notificaciones (correo_destino, canal, tipo, referencia_id, titulo, cuerpo)
    values (
      new.beneficiario_correo,
      'correo',
      'herencia_asignada',
      new.id,
      'Te dejaron un legado',
      coalesce(v_nombre, 'Alguien') || ' te asignó una pequeña herencia en Capsoul.'
    )
    on conflict do nothing;
  end if;

  if new.condicion_activacion = 'confirmacion_confianza'
     and new.persona_confianza_id is not null then
    insert into public.notificaciones (usuario_id, canal, tipo, referencia_id, titulo, cuerpo)
    values (
      new.persona_confianza_id,
      'push',
      'herencia_por_confirmar',
      new.id,
      'Te piden confirmar un legado',
      coalesce(v_nombre, 'Alguien') || ' te eligió como persona de confianza.'
    )
    on conflict do nothing;
  end if;

  return new;
end;
$$;

drop trigger if exists herencias_encolar_asignada on public.herencias;
create trigger herencias_encolar_asignada
  after insert or update of estado on public.herencias
  for each row execute function privado.encolar_aviso_herencia_asignada();

create or replace function privado.encolar_aviso_capsula_compartida()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  v_autor uuid;
  v_nombre text;
begin
  if new.usuario_id is null then
    return new;
  end if;

  select c.autor_id into v_autor
    from public.capsulas c where c.id = new.capsula_id;
  if v_autor is null or new.usuario_id = v_autor then
    return new;
  end if;

  select nullif(trim(u.nombre_visible), '') into v_nombre
    from public.usuarios u where u.id = v_autor;

  insert into public.notificaciones (usuario_id, canal, tipo, referencia_id, titulo, cuerpo)
  values (
    new.usuario_id,
    'push',
    'capsula_compartida',
    new.capsula_id,
    'Te compartieron una cápsula',
    coalesce(v_nombre, 'Alguien') || ' te dejó una cápsula del tiempo.'
  )
  on conflict do nothing;

  return new;
end;
$$;

drop trigger if exists capsula_destinatarios_encolar_aviso on public.capsula_destinatarios;
create trigger capsula_destinatarios_encolar_aviso
  after insert on public.capsula_destinatarios
  for each row execute function privado.encolar_aviso_capsula_compartida();

-- ---------------------------------------------------------------------
-- 8. RPC: vincular cápsula (el trigger otorga destinatario)
-- ---------------------------------------------------------------------
create or replace function public.vincular_capsula_herencia(p_herencia uuid, p_capsula uuid)
returns void language plpgsql volatile security definer set search_path = '' as $$
declare
  v_prop uuid;
begin
  if not privado.herencia_editable_por_mi(p_herencia) then
    raise exception 'herencia_no_editable';
  end if;
  select h.propietario_id into v_prop from public.herencias h where h.id = p_herencia;
  if not exists (
    select 1 from public.capsulas c
     where c.id = p_capsula and c.autor_id = v_prop
  ) then
    raise exception 'capsula_invalida';
  end if;
  insert into public.herencia_capsulas (herencia_id, capsula_id)
  values (p_herencia, p_capsula)
  on conflict do nothing;
  perform privado.registrar_evento_herencia(
    p_herencia, 'capsula_vinculada', jsonb_build_object('capsula_id', p_capsula)
  );
end;
$$;

-- ---------------------------------------------------------------------
-- 9. RPC de lectura sanitizada
-- ---------------------------------------------------------------------
create or replace function public.herencia_detalle(p_id uuid)
returns json language plpgsql stable security definer set search_path = '' as $$
declare
  h public.herencias;
  v_uid uuid := auth.uid();
  v_propietario boolean;
  v_beneficiario boolean;
  v_confianza boolean;
  v_contenido boolean;
  v_herencia json;
begin
  if v_uid is null then
    return null;
  end if;

  select * into h from public.herencias where id = p_id;
  if not found then
    return null;
  end if;

  v_propietario := h.propietario_id = v_uid;
  v_beneficiario := h.beneficiario_usuario_id = v_uid
                    and h.estado in ('activa', 'en_verificacion', 'liberada');
  v_confianza := h.persona_confianza_id = v_uid
                 and h.condicion_activacion = 'confirmacion_confianza'
                 and h.estado in ('activa', 'liberada');
  if not (v_propietario or v_beneficiario or v_confianza) then
    return null;
  end if;

  v_contenido := privado.puede_ver_contenido_herencia(h.id);

  if v_propietario or v_contenido then
    v_herencia := row_to_json(h);
  else
    v_herencia := json_build_object(
      'id', h.id,
      'propietario_id', h.propietario_id,
      'titulo', h.titulo,
      'descripcion', null,
      'beneficiario_usuario_id', h.beneficiario_usuario_id,
      'beneficiario_correo', null,
      'persona_confianza_id', h.persona_confianza_id,
      'condicion_activacion', h.condicion_activacion,
      'fecha_activacion', h.fecha_activacion,
      'dias_inactividad', h.dias_inactividad,
      'estado', h.estado,
      'verificacion_desde', h.verificacion_desde,
      'liberada_en', h.liberada_en,
      'metadatos', '{}'::jsonb,
      'creado_en', h.creado_en,
      'actualizado_en', h.actualizado_en
    );
  end if;

  return json_build_object(
    'herencia', v_herencia,
    'elementos', coalesce((
      select json_agg(json_build_object(
        'elemento_id', he.elemento_id,
        'orden', he.orden,
        'tipo', e.tipo
      ) order by he.orden)
      from public.herencia_elementos he
      join public.elementos e on e.id = he.elemento_id
      where he.herencia_id = h.id and v_contenido
    ), '[]'::json),
    'capsulas', coalesce((
      select json_agg(json_build_object(
        'capsula_id', hc.capsula_id,
        'orden', hc.orden,
        'titulo', case
          when c.autor_id = v_uid or c.estado = 'liberada' then c.titulo
          else 'Cápsula sellada'
        end,
        'estado', c.estado
      ) order by hc.orden)
      from public.herencia_capsulas hc
      join public.capsulas c on c.id = hc.capsula_id
      where hc.herencia_id = h.id
        and (c.autor_id = v_uid or privado.puede_ver_capsula(c.id))
    ), '[]'::json)
  );
end;
$$;

create or replace function public.herencias_recibidas()
returns table (
  id uuid,
  titulo text,
  estado text,
  condicion_activacion text,
  fecha_activacion timestamptz,
  propietario_id uuid,
  propietario_nombre text,
  contenido_visible boolean,
  descripcion text,
  metadatos jsonb,
  n_capsulas int,
  creado_en timestamptz
) language sql stable security definer set search_path = '' as $$
  select
    h.id,
    h.titulo,
    h.estado::text,
    h.condicion_activacion::text,
    h.fecha_activacion,
    h.propietario_id,
    coalesce(p.nombre_visible, 'Alguien'),
    (h.estado = 'liberada'),
    case when h.estado = 'liberada' then h.descripcion end,
    case when h.estado = 'liberada' then coalesce(h.metadatos, '{}'::jsonb) else '{}'::jsonb end,
    (
      select count(*)::int from public.herencia_capsulas hc where hc.herencia_id = h.id
    ),
    h.creado_en
  from public.herencias h
  left join public.usuarios p on p.id = h.propietario_id
  where h.beneficiario_usuario_id = auth.uid()
    and h.estado in ('activa', 'en_verificacion', 'liberada')
  order by h.creado_en desc;
$$;

create or replace function public.herencias_por_confirmar()
returns table (
  id uuid,
  titulo text,
  estado text,
  propietario_id uuid,
  propietario_nombre text,
  beneficiario_usuario_id uuid,
  beneficiario_nombre text,
  creado_en timestamptz
) language sql stable security definer set search_path = '' as $$
  select
    h.id,
    h.titulo,
    h.estado::text,
    h.propietario_id,
    coalesce(pp.nombre_visible, 'Alguien'),
    h.beneficiario_usuario_id,
    coalesce(pb.nombre_visible, 'Alguien'),
    h.creado_en
  from public.herencias h
  left join public.usuarios pp on pp.id = h.propietario_id
  left join public.usuarios pb on pb.id = h.beneficiario_usuario_id
  where h.persona_confianza_id = auth.uid()
    and h.condicion_activacion = 'confirmacion_confianza'
    and h.estado = 'activa'
  order by h.creado_en desc;
$$;

create or replace function public.actualizar_herencia_sellada(
  p_herencia uuid,
  p_titulo text,
  p_descripcion text,
  p_metadatos jsonb,
  p_fecha_activacion timestamptz default null
) returns void language plpgsql volatile security definer set search_path = '' as $$
declare
  h public.herencias;
begin
  if not privado.herencia_editable_por_mi(p_herencia) then
    raise exception 'herencia_no_editable';
  end if;
  select * into h from public.herencias where id = p_herencia for update;
  if not found then
    raise exception 'herencia_no_editable';
  end if;
  if p_titulo is null or char_length(trim(p_titulo)) < 1 then
    raise exception 'titulo_requerido';
  end if;
  update public.herencias
     set titulo = left(trim(p_titulo), 120),
         descripcion = nullif(trim(p_descripcion), ''),
         metadatos = coalesce(p_metadatos, '{}'::jsonb),
         fecha_activacion = case
           when h.condicion_activacion = 'fecha' and p_fecha_activacion is not null
             then p_fecha_activacion
           else fecha_activacion
         end,
         actualizado_en = now()
   where id = p_herencia;
end;
$$;

-- ---------------------------------------------------------------------
-- 10. Destinatarios de herencias ya existentes (el trigger no cubre el pasado)
-- ---------------------------------------------------------------------
select privado.sincronizar_destinatarios_herencia(id)
  from public.herencias
 where beneficiario_usuario_id is not null;

-- ---------------------------------------------------------------------
-- 11. Permisos
-- ---------------------------------------------------------------------
revoke all on function privado.sincronizar_destinatarios_herencia(uuid),
  privado.trg_herencia_capsulas_destinatarios(),
  privado.trg_herencias_beneficiario_destinatarios(),
  privado.encolar_aviso_herencia_asignada(),
  privado.encolar_aviso_capsula_compartida()
  from public, anon, authenticated;

revoke all on function public.herencias_recibidas(),
  public.herencias_por_confirmar(),
  public.actualizar_herencia_sellada(uuid, text, text, jsonb, timestamptz)
  from public, anon;
grant execute on function public.herencias_recibidas(),
  public.herencias_por_confirmar(),
  public.actualizar_herencia_sellada(uuid, text, text, jsonb, timestamptz)
  to authenticated;

commit;
