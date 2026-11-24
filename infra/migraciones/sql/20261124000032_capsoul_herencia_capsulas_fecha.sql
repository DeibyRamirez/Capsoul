-- Capsoul · Las cápsulas vinculadas respetan la fecha de la herencia.
-- - Un destinatario agregado por una herencia no ve la cápsula hasta que la
--   herencia está liberada, aunque la cápsula ya estuviera abierta.
-- - Al liberar la herencia, sus cápsulas `programada` pasan a `liberada`:
--   la fecha de la herencia es la que manda para el contenido vinculado.
-- - Solo se pueden vincular cápsulas propias en estado `programada` o
--   `liberada`; nunca cápsulas recibidas de otra persona ni borradores.

begin;

-- ---------------------------------------------------------------------
-- 1. Visibilidad de la cápsula: la herencia también es una puerta
-- ---------------------------------------------------------------------
create or replace function privado.puede_ver_capsula(p_capsula uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.capsulas c
    where c.id = p_capsula
      and (
        c.autor_id = (select auth.uid())
        or (
          c.estado = 'liberada'
          and (
            -- Destinatario directo: la compartieron fuera de una herencia.
            exists (
              select 1 from public.capsula_destinatarios d
              where d.capsula_id = c.id
                and d.usuario_id = (select auth.uid())
                and d.origen_herencia_id is null
            )
            -- Destinatario agregado por una herencia ya liberada.
            or exists (
              select 1
                from public.capsula_destinatarios d
                join public.herencias h on h.id = d.origen_herencia_id
               where d.capsula_id = c.id
                 and d.usuario_id = (select auth.uid())
                 and h.estado = 'liberada'
            )
            -- Beneficiario de una herencia liberada que vincula la cápsula.
            or exists (
              select 1
                from public.herencia_capsulas hc
                join public.herencias h on h.id = hc.herencia_id
               where hc.capsula_id = c.id
                 and h.estado = 'liberada'
                 and h.beneficiario_usuario_id = (select auth.uid())
            )
            -- Persona de confianza con acceso vigente.
            or exists (
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
      )
  );
$$;

-- ---------------------------------------------------------------------
-- 2. La lista de recibidas no muestra cápsulas de una herencia sin abrir
-- ---------------------------------------------------------------------
create or replace function public.capsulas_recibidas()
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
    and (
      d.origen_herencia_id is null
      or exists (
        select 1 from public.herencias h
        where h.id = d.origen_herencia_id
          and h.estado = 'liberada'
      )
      or exists (
        select 1
          from public.herencia_capsulas hc
          join public.herencias h on h.id = hc.herencia_id
         where hc.capsula_id = c.id
           and h.estado = 'liberada'
           and h.beneficiario_usuario_id = (select auth.uid())
      )
    )
  order by c.fecha_apertura;
$$;

-- ---------------------------------------------------------------------
-- 3. Liberar la herencia libera también sus cápsulas vinculadas
-- ---------------------------------------------------------------------
create or replace function privado.liberar_herencia(p_herencia uuid)
returns void language plpgsql volatile security definer set search_path = '' as $$
begin
  update public.herencias
     set estado = 'liberada', liberada_en = now(), verificacion_desde = null
   where id = p_herencia and estado in ('activa', 'en_verificacion');

  if found then
    update public.capsulas c
       set estado = 'liberada',
           liberada_en = coalesce(c.liberada_en, now())
      from public.herencia_capsulas hc
     where hc.herencia_id = p_herencia
       and hc.capsula_id = c.id
       and c.estado = 'programada';

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
-- 4. Vincular solo cápsulas propias y listas (no borradores ni ajenas)
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
     where c.id = p_capsula
       and c.autor_id = v_prop
       and c.estado in ('programada', 'liberada')
  ) then
    raise exception 'capsula_invalida';
  end if;
  insert into public.herencia_capsulas (herencia_id, capsula_id)
  values (p_herencia, p_capsula)
  on conflict do nothing;
  perform privado.registrar_evento_herencia(
    p_herencia, 'capsula_vinculada', jsonb_build_object('capsula_id', p_capsula)
  );
end $$;

-- ---------------------------------------------------------------------
-- 5. Backfill: cápsulas de herencias ya liberadas que seguían programadas
-- ---------------------------------------------------------------------
update public.capsulas c
   set estado = 'liberada',
       liberada_en = coalesce(c.liberada_en, now())
  from public.herencia_capsulas hc
  join public.herencias h on h.id = hc.herencia_id
 where hc.capsula_id = c.id
   and h.estado = 'liberada'
   and c.estado = 'programada';

commit;
