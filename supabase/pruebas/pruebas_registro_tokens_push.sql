-- Capsoul · Registro de tokens push por RPC (migración 000022).
\set ON_ERROR_STOP 1

insert into auth.users (id, email, raw_user_meta_data, email_confirmed_at) values
  ('99000000-0000-0000-0000-0000000000a1', 'token-uno@capsoul.app', '{"nombre_visible":"TokenUno"}', now()),
  ('99000000-0000-0000-0000-0000000000b1', 'token-dos@capsoul.app', '{"nombre_visible":"TokenDos"}', now())
on conflict do nothing;

-- Avisos de A: uno reciente sin token, uno viejo sin token, uno con otro error.
insert into public.notificaciones (id, usuario_id, canal, tipo, referencia_id, titulo, cuerpo, estado, intentos, ultimo_error, creado_en) values
  ('99100000-0000-0000-0000-000000000001', '99000000-0000-0000-0000-0000000000a1', 'push', 'solicitud_amistad', '99200000-0000-0000-0000-000000000001', 't', 'c', 'fallida', 5, 'Sin tokens FCM', now() - interval '1 hour'),
  ('99100000-0000-0000-0000-000000000002', '99000000-0000-0000-0000-0000000000a1', 'push', 'solicitud_amistad', '99200000-0000-0000-0000-000000000002', 't', 'c', 'fallida', 5, 'Sin tokens FCM', now() - interval '2 days'),
  ('99100000-0000-0000-0000-000000000003', '99000000-0000-0000-0000-0000000000a1', 'push', 'solicitud_amistad', '99200000-0000-0000-0000-000000000003', 't', 'c', 'fallida', 5, 'Token FCM inválido', now() - interval '1 hour');

-- anon no puede llamar la RPC.
set role anon;
do $$
begin
  begin
    perform public.registrar_dispositivo_push('token-anon', 'android');
    raise exception 'FALLO: anon registró un token';
  exception when insufficient_privilege then
    null;
  end;
end $$;
reset role;

-- A registra su token: se reactiva solo el aviso reciente sin token.
set role authenticated;
select set_config('request.jwt.claim.sub', '99000000-0000-0000-0000-0000000000a1', false);
do $$
declare n integer;
begin
  n := public.registrar_dispositivo_push('token-compartido', 'android');
  if n <> 1 then
    raise exception 'FALLO: se esperaba 1 aviso reactivado y hubo %', n;
  end if;
  begin
    perform public.registrar_dispositivo_push('token-x', 'web');
    raise exception 'FALLO: aceptó plataforma web';
  exception when raise_exception then
    if sqlerrm <> 'plataforma_invalida' then raise; end if;
  end;
  begin
    perform public.registrar_dispositivo_push('  ', 'ios');
    raise exception 'FALLO: aceptó token vacío';
  exception when raise_exception then
    if sqlerrm <> 'token_invalido' then raise; end if;
  end;
end $$;
reset role;

do $$
begin
  if (select estado from public.notificaciones where id = '99100000-0000-0000-0000-000000000001') <> 'pendiente'
     or (select intentos from public.notificaciones where id = '99100000-0000-0000-0000-000000000001') <> 0 then
    raise exception 'FALLO: el aviso reciente no se reactivó';
  end if;
  if (select estado from public.notificaciones where id = '99100000-0000-0000-0000-000000000002') <> 'fallida' then
    raise exception 'FALLO: se reactivó un aviso de más de 24 h';
  end if;
  if (select estado from public.notificaciones where id = '99100000-0000-0000-0000-000000000003') <> 'fallida' then
    raise exception 'FALLO: se reactivó un aviso con otro error';
  end if;
end $$;

-- B entra en el mismo teléfono: el token pasa a B (antes chocaba con el unique).
set role authenticated;
select set_config('request.jwt.claim.sub', '99000000-0000-0000-0000-0000000000b1', false);
select public.registrar_dispositivo_push('token-compartido', 'ios');
reset role;

do $$
begin
  if (select count(*) from public.dispositivos_push where token_fcm = 'token-compartido') <> 1 then
    raise exception 'FALLO: el token quedó duplicado';
  end if;
  if (select usuario_id from public.dispositivos_push where token_fcm = 'token-compartido')
     <> '99000000-0000-0000-0000-0000000000b1' then
    raise exception 'FALLO: el token no pasó a la cuenta nueva';
  end if;
  if (select plataforma from public.dispositivos_push where token_fcm = 'token-compartido') <> 'ios' then
    raise exception 'FALLO: no se actualizó la plataforma';
  end if;
  if exists (
    select 1 from pg_proc p join pg_namespace s on s.oid = p.pronamespace
     where s.nspname = 'public' and p.proname = 'registrar_dispositivo_push'
       and (not p.prosecdef or p.proconfig is distinct from array['search_path=""'])
  ) then
    raise exception 'FALLO: la RPC no es security definer con search_path vacío';
  end if;
end $$;

select 'pruebas_registro_tokens_push OK';
