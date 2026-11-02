-- Capsoul · Nuevos tipos de aviso para legado y cápsulas compartidas.
-- Cada valor se añade en su propia migración porque Postgres no deja usar un
-- enum nuevo hasta que el ADD VALUE queda confirmado.
-- No edita migraciones ya aplicadas.

alter type public.tipo_notificacion add value 'herencia_asignada';
alter type public.tipo_notificacion add value 'herencia_por_confirmar';
alter type public.tipo_notificacion add value 'capsula_compartida';
