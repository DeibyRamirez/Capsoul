---
name: capsoul-supabase-datos
description: >-
  Usar cuando se implementen repositorios de Capsoul que lean o escriban en
  Supabase (Postgres vía PostgREST, RPC) o que guarden metadatos de medios de
  Cloudinary (cápsulas, elementos, perfil, legado).
---
# Capsoul · Repositorios de datos con Supabase

Reemplaza a `capsoul-firestore-storage`.

## Capas
UI → controlador/notifier (Riverpod) → repositorio (interfaz en `dominio/`) → implementación en `datos/` →
SDK `supabase_flutter`. Nunca llamar a `Supabase.instance.client` desde widgets.

## Hábitos
1. Un repositorio por agregado (`RepositorioUsuarios`, `RepositorioCapsulas`, …) detrás de una interfaz
   abstracta inyectada por un provider (`proveedorRepositorio…`) para poder simularlo en pruebas.
2. Aislar el SDK en un adaptador delgado (p. ej. `AccesoTablaUsuarios`) cuando el constructor de consultas
   sea difícil de simular; el repositorio mapea filas y errores y es el que se prueba.
3. Mapear filas (`Map<String, dynamic>`) a modelos tipados con validación nula segura; **fallar cerrado** ante
   filas corruptas (tratarlas como inexistentes y registrar el error).
4. Filtrar siempre en la consulta aunque RLS ya restrinja (`.eq('usuario_id', uid)`): mejora el plan.
5. Seleccionar solo las columnas necesarias (`select('id, nombre_visible')`), paginar con cursores y `limit`.
6. Escrituras de varias tablas que deben ser consistentes → función SQL transaccional vía `rpc()`.
7. Tiempo real (`stream()`/Realtime) solo si la tabla está en la publicación de Realtime (cambio de entorno,
   pedir aprobación); si no, recargar tras escribir.
8. Errores: traducir `PostgrestException` (`42501` permiso, `PGRST116` sin filas), `SocketException` (sin red)
   y `AuthException` a fallos de dominio con mensaje en español.
9. Medios: el archivo vive en Cloudinary; en Postgres solo `cloudinary_public_id`, `url`, `formato`, `bytes`,
   `duracion` y metadatos (ver `capsoul-cloudinary-medios`).

## Listo cuando
- El repositorio es probable con una interfaz y un falso/adaptador
- Los errores están tipados y en español
- No hay secretos en el cliente
- Las consultas coinciden con las políticas RLS y los índices existentes

## Fuentes
- Supabase, referencia Dart (consultas, filtros, `rpc`, `stream`): https://supabase.com/docs/reference/dart/select
- Supabase, "RLS performance" (filtrar también en el cliente): https://supabase.com/docs/guides/database/postgres/row-level-security-performance
- PostgREST, códigos de error: https://docs.postgrest.org/en/stable/references/errors.html
- Supabase Agent Skills, `supabase-postgres-best-practices`: https://github.com/supabase/agent-skills
