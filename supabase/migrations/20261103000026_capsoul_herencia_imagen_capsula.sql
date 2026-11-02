-- Capsoul · imagen_clave de cápsulas vinculadas en herencia_detalle.
-- La clave es catálogo local (capsula_01…16), no contenido sellado.
-- No edita migraciones ya aplicadas.

begin;

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
        'estado', c.estado,
        'imagen_clave', c.imagen_clave
      ) order by hc.orden)
      from public.herencia_capsulas hc
      join public.capsulas c on c.id = hc.capsula_id
      where hc.herencia_id = h.id
        and (c.autor_id = v_uid or privado.puede_ver_capsula(c.id))
    ), '[]'::json)
  );
end;
$$;

grant execute on function public.herencia_detalle(uuid) to authenticated;

commit;
