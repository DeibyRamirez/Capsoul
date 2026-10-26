-- Deja la base local lista para volver a aplicar las migraciones.
-- No borra la base `postgres` (ahí vive pg_cron) ni las extensiones.

do $$
declare
  trabajo record;
begin
  if to_regnamespace('cron') is not null then
    for trabajo in select jobname from cron.job loop
      perform cron.unschedule(trabajo.jobname);
    end loop;
  end if;
end $$;

drop schema if exists public cascade;
drop schema if exists privado cascade;
drop schema if exists auth cascade;

create schema public;
grant usage on schema public to public;
grant all on schema public to postgres;
