-- Capsoul · Acceso de la persona de confianza con código por correo.
-- Requiere 20261026000018 (notificaciones.reclamado_en) para el reenvío y
-- para que la Edge Function enviar-avisos pueda reclamar el aviso.
-- - La persona de confianza se elige por herencia (o se hereda la global).
-- - Al liberar la herencia se encola un correo para esa persona.
-- - El código se guarda con hash bcrypt; nunca en texto plano.
-- - El código solo sirve si la herencia ya está liberada y para la persona
--   de confianza asignada.
-- - Al validarlo se concede acceso temporal al contenido de la herencia.

begin;

-- ---------------------------------------------------------------------
-- 1. Códigos de acceso (solo servidor) y accesos concedidos
-- ---------------------------------------------------------------------
create table if not exists public.herencia_codigos (
  id              uuid primary key default gen_random_uuid(),
  herencia_id     uuid not null references public.herencias (id) on delete cascade,
  usuario_id      uuid not null references public.usuarios (id) on delete cascade,
  codigo_hash     text not null,
  expira_en       timestamptz not null,
  usado_en        timestamptz,
  revocado_en     timestamptz,
  intentos        smallint not null default 0 check (intentos >= 0),
  bloqueado_hasta timestamptz,
  creado_en       timestamptz not null default now()
);

create index if not exists herencia_codigos_vigentes_idx
  on public.herencia_codigos (herencia_id, usuario_id, creado_en desc)
  where usado_en is null and revocado_en is null;

-- Un solo código vigente por herencia y persona.
create unique index if not exists herencia_codigos_un_vigente_idx
  on public.herencia_codigos (herencia_id, usuario_id)
  where usado_en is null and revocado_en is null;

create table if not exists public.herencia_accesos (
  herencia_id  uuid not null references public.herencias (id) on delete cascade,
  usuario_id   uuid not null references public.usuarios (id) on delete cascade,
  concedido_en timestamptz not null default now(),
  expira_en    timestamptz not null,
  primary key (herencia_id, usuario_id)
);

create index if not exists herencia_accesos_usuario_idx
  on public.herencia_accesos (usuario_id, expira_en);

alter table public.herencia_codigos enable row level security;
alter table public.herencia_accesos enable row level security;

revoke all on public.herencia_codigos, public.herencia_accesos
  from public, anon, authenticated;
grant select, insert, update, delete
  on public.herencia_codigos, public.herencia_accesos
  to service_role;

comment on table public.herencia_codigos is
  'Códigos de acceso al legado. El código va con hash bcrypt; no se expone al cliente.';
comment on table public.herencia_accesos is
  'Acceso temporal concedido a la persona de confianza tras validar su código.';

-- ---------------------------------------------------------------------
-- 2. Validar que la persona de confianza sea amiga y distinta del beneficiario
-- ---------------------------------------------------------------------
create or replace function privado.validar_persona_confianza_herencia()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if new.persona_confianza_id is not null then
    if not privado.son_amigos(new.propietario_id, new.persona_confianza_id) then
      raise exception 'confianza_debe_ser_amigo';
    end if;
    if new.beneficiario_usuario_id is not null
       and new.beneficiario_usuario_id = new.persona_confianza_id then
      raise exception 'confianza_no_beneficiario';
    end if;
  end if;
  return new;
end $$;

drop trigger if exists herencias_validar_confianza on public.herencias;
create trigger herencias_validar_confianza
  before insert or update of persona_confianza_id, beneficiario_usuario_id, propietario_id
  on public.herencias
  for each row execute function privado.validar_persona_confianza_herencia();

-- ---------------------------------------------------------------------
-- 3. Permisos de contenido: la persona de confianza necesita un acceso vigente
-- ---------------------------------------------------------------------
create or replace function privado.puede_ver_contenido_herencia(p_herencia uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.herencias h
    where h.id = p_herencia
      and (
        h.propietario_id = (select auth.uid())
        or (
          h.estado = 'liberada'
          and h.beneficiario_usuario_id = (select auth.uid())
        )
        or (
          h.estado = 'liberada'
          and h.persona_confianza_id = (select auth.uid())
          and exists (
            select 1 from public.herencia_accesos a
            where a.herencia_id = h.id
              and a.usuario_id = (select auth.uid())
              and a.expira_en > now()
          )
        )
      )
  );
$$;

-- La persona de confianza con acceso puede abrir las cápsulas vinculadas
-- cuando la cápsula ya esté liberada (respeta su propia fecha).
create or replace function privado.puede_ver_capsula(p_capsula uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.capsulas c
    where c.id = p_capsula
      and (
        c.autor_id = (select auth.uid())
        or (
          c.estado = 'liberada'
          and exists (
            select 1 from public.capsula_destinatarios d
            where d.capsula_id = c.id and d.usuario_id = (select auth.uid())
          )
        )
        or (
          c.estado = 'liberada'
          and exists (
            select 1
              from public.herencia_capsulas hc
              join public.herencias h on h.id = hc.herencia_id
              join public.herencia_accesos a on a.herencia_id = h.id
             where hc.capsula_id = c.id
               and h.estado = 'liberada'
               and h.persona_confianza_id = (select auth.uid())
               and a.usuario_id = (select auth.uid())
               and a.expira_en > now()
          )
        )
      )
  );
$$;

-- ---------------------------------------------------------------------
-- 4. Liberar la herencia y encolar el correo con el código
-- ---------------------------------------------------------------------
create or replace function privado.liberar_herencia(p_herencia uuid)
returns void language plpgsql volatile security definer set search_path = '' as $$
begin
  update public.herencias
     set estado = 'liberada', liberada_en = now(), verificacion_desde = null
   where id = p_herencia and estado in ('activa', 'en_verificacion');

  if found then
    insert into public.notificaciones (
      usuario_id, correo_destino, canal, tipo, referencia_id, titulo, cuerpo
    )
    select h.beneficiario_usuario_id,
           case when h.beneficiario_usuario_id is null then h.beneficiario_correo end,
           case when h.beneficiario_usuario_id is null then 'correo' else 'push' end::public.canal_notificacion,
           'herencia_liberada', h.id, 'Tienes un legado disponible',
           'Una herencia se activó y ya puedes verla.'
      from public.herencias h where h.id = p_herencia
    on conflict do nothing;

    -- Código para la persona de confianza. El texto del aviso no lleva el
    -- código: lo genera la Edge Function y lo envía por correo.
    insert into public.notificaciones (
      usuario_id, correo_destino, canal, tipo, referencia_id, titulo, cuerpo
    )
    select h.persona_confianza_id,
           u.correo,
           'correo'::public.canal_notificacion,
           'herencia_codigo_acceso'::public.tipo_notificacion,
           h.id,
           'Tu código para abrir el legado',
           'La herencia se abrió. Te enviamos un código para que puedas verla y ayudar.'
      from public.herencias h
      join public.usuarios u on u.id = h.persona_confianza_id
     where h.id = p_herencia
       and h.persona_confianza_id is not null
    on conflict do nothing;

    insert into public.herencia_eventos (herencia_id, tipo, actor_id, detalle)
    values (p_herencia, 'liberada', null, '{}'::jsonb);
  end if;
end $$;

-- ---------------------------------------------------------------------
-- 5. Generar el código (solo service_role / Edge Function)
-- ---------------------------------------------------------------------
create or replace function public.generar_codigo_herencia(
  p_herencia uuid,
  p_usuario uuid
)
returns table (
  codigo text,
  expira_en timestamptz,
  titulo text,
  propietario_nombre text
)
language plpgsql volatile security definer set search_path = '' as $$
declare
  v_bytes bytea;
  v_aleatorio bigint;
  v_codigo text;
  v_hash text;
  v_expira timestamptz := now() + interval '20 minutes';
  v_titulo text;
  v_propietario text;
begin
  select h.titulo, coalesce(u.nombre_visible, 'Alguien')
    into v_titulo, v_propietario
    from public.herencias h
    join public.usuarios u on u.id = h.propietario_id
   where h.id = p_herencia
     and h.estado = 'liberada'
     and h.persona_confianza_id = p_usuario;

  if not found then
    raise exception 'sin_permiso';
  end if;

  update public.herencia_codigos
     set revocado_en = now()
   where herencia_id = p_herencia
     and usuario_id = p_usuario
     and usado_en is null
     and revocado_en is null;

  v_bytes := extensions.gen_random_bytes(4);
  v_aleatorio := (get_byte(v_bytes, 0)::bigint << 24)
               | (get_byte(v_bytes, 1)::bigint << 16)
               | (get_byte(v_bytes, 2)::bigint << 8)
               | get_byte(v_bytes, 3)::bigint;
  v_codigo := lpad((v_aleatorio % 1000000)::text, 6, '0');
  v_hash := extensions.crypt(v_codigo, extensions.gen_salt('bf', 10));

  insert into public.herencia_codigos (
    herencia_id, usuario_id, codigo_hash, expira_en
  ) values (
    p_herencia, p_usuario, v_hash, v_expira
  );

  return query select v_codigo, v_expira, v_titulo, v_propietario;
end $$;

-- ---------------------------------------------------------------------
-- 6. La persona de confianza pide reenviar el código
-- ---------------------------------------------------------------------
create or replace function public.solicitar_codigo_herencia(p_herencia uuid)
returns json language plpgsql volatile security definer set search_path = '' as $$
declare
  v_uid uuid := auth.uid();
  v_correo text;
  v_aviso uuid;
  v_ultimo timestamptz;
  v_reclamado timestamptz;
  v_estado public.estado_notificacion;
begin
  if v_uid is null then
    return json_build_object('ok', false, 'codigo', 'sin_sesion');
  end if;

  select u.correo into v_correo
    from public.herencias h
    join public.usuarios u on u.id = h.persona_confianza_id
   where h.id = p_herencia
     and h.estado = 'liberada'
     and h.persona_confianza_id = v_uid;

  if not found then
    return json_build_object('ok', false, 'codigo', 'sin_permiso');
  end if;

  select n.id, n.creado_en, n.reclamado_en, n.estado
    into v_aviso, v_ultimo, v_reclamado, v_estado
    from public.notificaciones n
   where n.tipo = 'herencia_codigo_acceso'
     and n.referencia_id = p_herencia
     and n.usuario_id = v_uid
     and n.canal = 'correo'
   order by n.creado_en desc
   limit 1;

  if v_ultimo is not null and v_ultimo > now() - interval '60 seconds' then
    return json_build_object('ok', false, 'codigo', 'espera_reenvio');
  end if;

  -- Si el worker ya la está enviando, no se pisa el aviso en vuelo.
  if v_estado = 'pendiente'
     and v_reclamado is not null
     and v_reclamado > now() - interval '5 minutes' then
    return json_build_object('ok', false, 'codigo', 'espera_reenvio');
  end if;

  update public.herencia_codigos
     set revocado_en = now()
   where herencia_id = p_herencia
     and usuario_id = v_uid
     and usado_en is null
     and revocado_en is null;

  if v_aviso is null then
    insert into public.notificaciones (
      usuario_id, correo_destino, canal, tipo, referencia_id, titulo, cuerpo
    ) values (
      v_uid, v_correo, 'correo', 'herencia_codigo_acceso', p_herencia,
      'Tu código para abrir el legado',
      'La herencia se abrió. Te enviamos un código para que puedas verla y ayudar.'
    );
  else
    update public.notificaciones
       set estado = 'pendiente', intentos = 0, ultimo_error = null,
           reclamado_en = null, enviada_en = null, creado_en = now(),
           correo_destino = v_correo
     where id = v_aviso;
  end if;

  return json_build_object('ok', true);
end $$;

-- ---------------------------------------------------------------------
-- 7. Validar el código y conceder acceso temporal
-- ---------------------------------------------------------------------
create or replace function public.validar_codigo_herencia(
  p_herencia uuid,
  p_codigo text
)
returns json language plpgsql volatile security definer set search_path = '' as $$
declare
  v_uid uuid := auth.uid();
  v_codigo public.herencia_codigos;
  v_ok boolean := false;
  v_expira timestamptz;
  v_restantes integer;
begin
  if v_uid is null then
    return json_build_object('ok', false, 'codigo', 'sin_sesion');
  end if;
  if p_codigo is null or btrim(p_codigo) !~ '^[0-9]{6}$' then
    return json_build_object(
      'ok', false,
      'codigo', 'codigo_incorrecto',
      'mensaje', 'El código debe tener 6 dígitos.'
    );
  end if;

  if not exists (
    select 1 from public.herencias h
    where h.id = p_herencia
      and h.estado = 'liberada'
      and h.persona_confianza_id = v_uid
  ) then
    return json_build_object('ok', false, 'codigo', 'sin_permiso');
  end if;

  select * into v_codigo
    from public.herencia_codigos c
   where c.herencia_id = p_herencia
     and c.usuario_id = v_uid
     and c.usado_en is null
     and c.revocado_en is null
   order by c.creado_en desc
   limit 1
   for update;

  if not found then
    return json_build_object('ok', false, 'codigo', 'codigo_no_vigente');
  end if;
  if v_codigo.expira_en <= now() then
    return json_build_object('ok', false, 'codigo', 'codigo_no_vigente');
  end if;
  if v_codigo.bloqueado_hasta is not null and v_codigo.bloqueado_hasta > now() then
    return json_build_object(
      'ok', false,
      'codigo', 'codigo_bloqueado',
      'bloqueado_hasta', v_codigo.bloqueado_hasta
    );
  end if;

  v_ok := extensions.crypt(btrim(p_codigo), v_codigo.codigo_hash) = v_codigo.codigo_hash;

  if v_ok then
    update public.herencia_codigos
       set usado_en = now()
     where id = v_codigo.id;

    v_expira := now() + interval '24 hours';
    insert into public.herencia_accesos (herencia_id, usuario_id, concedido_en, expira_en)
    values (p_herencia, v_uid, now(), v_expira)
    on conflict (herencia_id, usuario_id) do update
      set concedido_en = now(), expira_en = excluded.expira_en;

    insert into public.herencia_eventos (herencia_id, tipo, actor_id, detalle)
    values (p_herencia, 'codigo_acceso_validado', v_uid, '{}'::jsonb);

    return json_build_object('ok', true, 'acceso_expira_en', v_expira);
  end if;

  update public.herencia_codigos
     set intentos = intentos + 1,
         bloqueado_hasta = case
           when intentos + 1 >= 5 then now() + interval '15 minutes'
           else bloqueado_hasta
         end
   where id = v_codigo.id;

  v_restantes := greatest(5 - (v_codigo.intentos + 1), 0);

  insert into public.herencia_eventos (herencia_id, tipo, actor_id, detalle)
  values (
    p_herencia, 'codigo_acceso_fallido', v_uid,
    jsonb_build_object('intentos', v_codigo.intentos + 1)
  );

  return json_build_object(
    'ok', false,
    'codigo', 'codigo_incorrecto',
    'intentos_restantes', v_restantes
  );
end $$;

-- ---------------------------------------------------------------------
-- 8. Estado del acceso para la pantalla de desbloqueo
-- ---------------------------------------------------------------------
create or replace function public.estado_acceso_herencia(p_herencia uuid)
returns json language sql stable security definer set search_path = '' as $$
  with h as (
    select * from public.herencias where id = p_herencia
  ), acceso as (
    select * from public.herencia_accesos
     where herencia_id = p_herencia
       and usuario_id = (select auth.uid())
       and expira_en > now()
  ), codigo as (
    select * from public.herencia_codigos
     where herencia_id = p_herencia
       and usuario_id = (select auth.uid())
       and usado_en is null
       and revocado_en is null
       and expira_en > now()
     order by creado_en desc
     limit 1
  ), aviso as (
    select creado_en from public.notificaciones
     where tipo = 'herencia_codigo_acceso'
       and referencia_id = p_herencia
       and usuario_id = (select auth.uid())
       and canal = 'correo'
     order by creado_en desc
     limit 1
  )
  select json_build_object(
    'es_confianza', (select persona_confianza_id = (select auth.uid()) from h),
    'liberada', (select estado = 'liberada' from h),
    'acceso_activo', exists (select 1 from acceso),
    'acceso_expira_en', (select expira_en from acceso),
    'codigo_vigente', exists (select 1 from codigo),
    'codigo_expira_en', (select expira_en from codigo),
    'intentos_restantes', (select greatest(5 - intentos, 0) from codigo),
    'bloqueado_hasta', (select bloqueado_hasta from codigo),
    'reenvio_disponible_en', (select creado_en + interval '60 seconds' from aviso)
  );
$$;

-- ---------------------------------------------------------------------
-- 9. Listado de herencias donde soy persona de confianza
-- ---------------------------------------------------------------------
create or replace function public.herencias_a_mi_cuidado()
returns table (
  id uuid,
  titulo text,
  estado text,
  condicion_activacion text,
  fecha_activacion timestamptz,
  propietario_id uuid,
  propietario_nombre text,
  contenido_visible boolean,
  acceso_activo boolean,
  acceso_expira_en timestamptz,
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
    (
      h.estado = 'liberada'
      and exists (
        select 1 from public.herencia_accesos a
        where a.herencia_id = h.id
          and a.usuario_id = auth.uid()
          and a.expira_en > now()
      )
    ),
    exists (
      select 1 from public.herencia_accesos a
      where a.herencia_id = h.id
        and a.usuario_id = auth.uid()
        and a.expira_en > now()
    ),
    (
      select a.expira_en from public.herencia_accesos a
      where a.herencia_id = h.id
        and a.usuario_id = auth.uid()
        and a.expira_en > now()
      limit 1
    ),
    (
      select count(*)::int from public.herencia_capsulas hc
      where hc.herencia_id = h.id
    ),
    h.creado_en
  from public.herencias h
  left join public.usuarios p on p.id = h.propietario_id
  where h.persona_confianza_id = auth.uid()
    and h.estado in ('activa', 'en_verificacion', 'liberada')
  order by h.creado_en desc;
$$;

-- ---------------------------------------------------------------------
-- 10. Detalle con estado de acceso para la persona de confianza
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
  v_acceso_expira timestamptz;
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
                 and h.estado in ('activa', 'en_verificacion', 'liberada');
  if not (v_propietario or v_beneficiario or v_confianza) then
    return null;
  end if;

  v_contenido := privado.puede_ver_contenido_herencia(h.id);

  if v_contenido and v_confianza then
    select a.expira_en into v_acceso_expira
      from public.herencia_accesos a
     where a.herencia_id = h.id
       and a.usuario_id = v_uid
       and a.expira_en > now()
     limit 1;
  end if;

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
    'acceso', json_build_object(
      'es_confianza', v_confianza,
      'activo', v_contenido and v_confianza,
      'expira_en', v_acceso_expira
    ),
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
        'estado', c.estado,
        'imagen_clave', c.imagen_clave
      ) order by hc.orden)
      from public.herencia_capsulas hc
      join public.capsulas c on c.id = hc.capsula_id
      where hc.herencia_id = h.id
        and (c.autor_id = v_uid or privado.puede_ver_capsula(c.id))
    ), '[]'::json)
  );
end $$;

-- ---------------------------------------------------------------------
-- 11. Cambiar la persona de confianza de una herencia sellada
-- ---------------------------------------------------------------------
create or replace function public.actualizar_persona_confianza_herencia(
  p_herencia uuid,
  p_persona_confianza uuid
)
returns void language plpgsql volatile security definer set search_path = '' as $$
declare
  v_prop uuid;
  v_benef uuid;
  v_anterior uuid;
  v_condicion public.condicion_herencia;
  v_estado public.estado_herencia;
begin
  if not privado.herencia_editable_por_mi(p_herencia) then
    raise exception 'herencia_no_editable';
  end if;

  select propietario_id, beneficiario_usuario_id, persona_confianza_id,
         condicion_activacion, estado
    into v_prop, v_benef, v_anterior, v_condicion, v_estado
    from public.herencias
   where id = p_herencia
   for update;

  if not found then
    raise exception 'herencia_no_editable';
  end if;
  if p_persona_confianza is null then
    raise exception 'confianza_requerida';
  end if;
  if not privado.son_amigos(v_prop, p_persona_confianza) then
    raise exception 'confianza_debe_ser_amigo';
  end if;
  if v_benef is not null and v_benef = p_persona_confianza then
    raise exception 'confianza_no_beneficiario';
  end if;

  if v_anterior is distinct from p_persona_confianza then
    delete from public.herencia_accesos where herencia_id = p_herencia;
    update public.herencia_codigos
       set revocado_en = now()
     where herencia_id = p_herencia
       and usado_en is null
       and revocado_en is null;

    update public.herencias
       set persona_confianza_id = p_persona_confianza,
           actualizado_en = now()
     where id = p_herencia;

    -- El aviso de confirmación del anterior ya no aplica.
    delete from public.notificaciones
     where tipo = 'herencia_por_confirmar'
       and referencia_id = p_herencia
       and usuario_id = v_anterior
       and estado = 'pendiente';

    if v_condicion = 'confirmacion_confianza' and v_estado = 'activa' then
      insert into public.notificaciones (
        usuario_id, canal, tipo, referencia_id, titulo, cuerpo
      ) values (
        p_persona_confianza,
        'push',
        'herencia_por_confirmar',
        p_herencia,
        'Te piden confirmar un legado',
        'Te eligieron como persona de confianza de un legado.'
      )
      on conflict do nothing;
    end if;

    perform privado.registrar_evento_herencia(
      p_herencia,
      'confianza_actualizada',
      jsonb_build_object('anterior', v_anterior, 'nueva', p_persona_confianza)
    );
  end if;
end $$;

-- ---------------------------------------------------------------------
-- 12. Permisos
-- ---------------------------------------------------------------------
revoke all on function privado.validar_persona_confianza_herencia()
  from public, anon, authenticated;

revoke all on function public.generar_codigo_herencia(uuid, uuid)
  from public, anon, authenticated;
grant execute on function public.generar_codigo_herencia(uuid, uuid)
  to service_role;

revoke all on function public.solicitar_codigo_herencia(uuid),
  public.validar_codigo_herencia(uuid, text),
  public.estado_acceso_herencia(uuid),
  public.herencias_a_mi_cuidado(),
  public.actualizar_persona_confianza_herencia(uuid, uuid)
  from public, anon;

grant execute on function public.solicitar_codigo_herencia(uuid),
  public.validar_codigo_herencia(uuid, text),
  public.estado_acceso_herencia(uuid),
  public.herencias_a_mi_cuidado(),
  public.actualizar_persona_confianza_herencia(uuid, uuid)
  to authenticated;

commit;
