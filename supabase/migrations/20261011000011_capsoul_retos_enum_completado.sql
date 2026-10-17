-- Postgres 55P04: el valor nuevo del enum debe commitearse antes de usarlo en funciones.
alter type public.estado_participacion add value if not exists 'completado';
