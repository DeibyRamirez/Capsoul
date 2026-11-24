-- Capsoul · Tipo de aviso para el código de acceso a una herencia.
-- Se separa en su propia migración porque Postgres no permite usar un valor
-- nuevo del enum dentro de la misma transacción en la que se agrega.

alter type public.tipo_notificacion add value if not exists 'herencia_codigo_acceso';
