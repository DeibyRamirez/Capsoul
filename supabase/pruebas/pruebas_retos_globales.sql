-- Capsoul · Catálogo de retos globales (000012).
\set ON_ERROR_STOP 1

do $$
declare n integer;
begin
  select count(*) into n from public.retos where slug = 'primer_capsula';
  if n <> 1 then
    raise exception 'FALLO: falta el reto primer_capsula (hay %)', n;
  end if;
end $$;

insert into auth.users (id, email, raw_user_meta_data, email_confirmed_at) values
  ('00000000-0000-0000-0000-0000000095aa', 'retos@capsoul.app', '{"nombre_visible":"Retos"}', now())
on conflict do nothing;

set role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-0000000095aa', false);

do $$
declare n integer;
begin
  select count(*) into n from public.listar_retos_globales();
  if n < 1 then
    raise exception 'FALLO: listar_retos_globales no devolvió el catálogo';
  end if;
  n := public.contar_retos_pendientes();
  if n < 1 then
    raise exception 'FALLO: contar_retos_pendientes quedó en 0';
  end if;
end $$;

reset role;
select 'OK retos globales' as r;
