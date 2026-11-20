-- Diario · refuerza el search_path de las funciones creadas en la migración 28.
--
-- La migración 28 ya se aplicó en remoto con `search_path = public`. Esta
-- migración deja las funciones en `search_path = ''` (todas sus referencias ya
-- están calificadas) para cumplir la prueba de seguridad de funciones
-- SECURITY DEFINER. También corrige instalaciones nuevas porque la 28 ya quedó
-- con el valor vacío.

alter function privado.cumple_criterio_reto(uuid, text, jsonb)
  set search_path = '';
alter function privado.trg_evaluar_retos_usuarios()
  set search_path = '';
alter function privado.trg_evaluar_retos_capsula_elementos()
  set search_path = '';
alter function privado.trg_evaluar_retos_momento_elementos()
  set search_path = '';
alter function privado.trg_evaluar_retos_capsula_destinatarios()
  set search_path = '';
alter function privado.trg_evaluar_retos_herencia_capsulas()
  set search_path = '';

notify pgrst, 'reload schema';
