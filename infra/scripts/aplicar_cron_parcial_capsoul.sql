-- Capsoul · Cron parcial (migración 000002, solo jobs 1 y 2)
-- Ejecutar en Supabase SQL Editor DESPUÉS de habilitar pg_cron y pg_net (Dashboard → Extensions).
-- NO incluye capsoul-enviar-avisos (pendiente Edge Function enviar-avisos + Vault).
--
-- Antes de ejecutar:
--   select jobid, jobname from cron.job where jobname like 'capsoul-%';
-- Si ya existen los jobs, no vuelvas a programarlos.

begin;

create extension if not exists pg_cron with schema pg_catalog;
create extension if not exists pg_net with schema extensions;

select cron.schedule(
  'capsoul-liberar-capsulas',
  '* * * * *',
  $$ select privado.liberar_capsulas_vencidas(); $$
);

select cron.schedule(
  'capsoul-activar-herencias',
  '0 * * * *',
  $$ select privado.activar_herencias(); $$
);

commit;
