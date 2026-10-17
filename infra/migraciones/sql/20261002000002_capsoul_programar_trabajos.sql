-- =====================================================================
-- REQUISITOS ANTES DE APLICAR ESTA MIGRACIÓN (si falta alguno, NO aplicarla):
--   1. Migración 20261002000001_capsoul_modelo_inicial.sql ya aplicada.
--   2. Extensiones habilitadas en el proyecto (Dashboard → Database → Extensions):
--        * pg_cron  (Supabase Cron)
--        * pg_net   (llamadas HTTP desde Postgres)
--   3. Secretos creados en Supabase Vault (desde el SQL Editor, NUNCA en el repo):
--        * project_url  → https://<ref>.supabase.co
--        * llave_cron   → llave secreta de un solo uso para invocar la Edge Function
--   4. Edge Function "enviar-avisos" desplegada (la invoca el trabajo 3).
--   Con el plan Free, si el proyecto se pausa, pg_cron no corre (decisión D1 del PO).
-- =====================================================================
-- Capsoul · Programación de trabajos con Supabase Cron (pg_cron + pg_net)
-- BORRADOR 1.1 · 2026-10-02 · Propuesta del Scrum Master, pendiente de confirmar.
-- Requiere: migración 000001 aplicada; extensiones pg_cron y pg_net habilitadas;
-- secretos en Supabase Vault. Fuentes:
--   https://supabase.com/docs/guides/cron/install
--   https://supabase.com/docs/guides/functions/schedule-functions
-- NUNCA escribir llaves en este archivo: se leen desde Vault.
-- =====================================================================

create extension if not exists pg_cron with schema pg_catalog;
create extension if not exists pg_net  with schema extensions;

-- 1) Liberar cápsulas vencidas cada minuto (todo dentro de Postgres, sin red).
select cron.schedule(
  'capsoul-liberar-capsulas',
  '* * * * *',
  $$ select privado.liberar_capsulas_vencidas(); $$
);

-- 2) Activar herencias (por fecha / inactividad) una vez por hora.
select cron.schedule(
  'capsoul-activar-herencias',
  '0 * * * *',
  $$ select privado.activar_herencias(); $$
);

-- 3) Despachar avisos pendientes: invoca la Edge Function "enviar-avisos" cada minuto.
--    La función lee public.notificaciones (estado = 'pendiente'), envía push por la
--    API HTTP v1 de FCM o correo, y marca enviada / fallida con reintentos.
--    Antes, cargar en Vault (una sola vez, desde el SQL Editor, NO en el repo):
--      select vault.create_secret('https://<ref>.supabase.co', 'project_url');
--      select vault.create_secret('<llave secreta sb_secret_... de un solo uso para cron>', 'llave_cron');
select cron.schedule(
  'capsoul-enviar-avisos',
  '* * * * *',
  $$
  select net.http_post(
    url     := (select decrypted_secret from vault.decrypted_secrets where name = 'project_url') || '/functions/v1/enviar-avisos',
    headers := jsonb_build_object(
                 'Content-Type', 'application/json',
                 'apikey', (select decrypted_secret from vault.decrypted_secrets where name = 'llave_cron')),
    body    := jsonb_build_object('origen', 'cron', 'hora', now())
  ) as id_solicitud;
  $$
);

-- Monitoreo: select * from cron.job_run_details order by start_time desc limit 20;
