-- Capsoul · Registro de tokens push por RPC y reactivación de avisos sin token.
-- 1. public.registrar_dispositivo_push(p_token, p_plataforma): upsert por
--    token_fcm con usuario_id = auth.uid(). Si el teléfono cambió de cuenta,
--    el token pasa a la cuenta nueva (con RLS el cliente no podía verlo y el
--    insert chocaba con el unique de token_fcm).
-- 2. Al registrar un token se reactivan los avisos push del usuario que
--    fallaron con 'Sin tokens FCM' en las últimas 24 h (pendiente, intentos 0).
--    enviar-avisos los toma en el siguiente minuto. No cambia la función.

begin;

create or replace function public.registrar_dispositivo_push(p_token text, p_plataforma text)
returns integer
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  yo uuid := auth.uid();
  v_token text := nullif(trim(p_token), '');
  v_reactivados integer;
begin
  if yo is null then
    raise exception 'sin_sesion';
  end if;
  if v_token is null or length(v_token) > 4096 then
    raise exception 'token_invalido';
  end if;
  if p_plataforma is null or p_plataforma not in ('android', 'ios') then
    raise exception 'plataforma_invalida';
  end if;

  insert into public.dispositivos_push (usuario_id, token_fcm, plataforma, ultimo_uso_en)
  values (yo, v_token, p_plataforma, now())
  on conflict (token_fcm) do update
     set usuario_id    = excluded.usuario_id,
         plataforma    = excluded.plataforma,
         ultimo_uso_en = now();

  update public.notificaciones n
     set estado = 'pendiente',
         intentos = 0,
         ultimo_error = null,
         reclamado_en = null
   where n.usuario_id = yo
     and n.canal = 'push'
     and n.estado = 'fallida'
     and n.ultimo_error = 'Sin tokens FCM'
     and n.creado_en > now() - interval '24 hours';
  get diagnostics v_reactivados = row_count;

  return v_reactivados;
end;
$$;

revoke all on function public.registrar_dispositivo_push(text, text) from public, anon;
grant execute on function public.registrar_dispositivo_push(text, text) to authenticated;

commit;
