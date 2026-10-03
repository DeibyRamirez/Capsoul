---
name: capsoul-supabase-postgres-sql
description: >-
  Usar cuando se diseñe o revise el esquema SQL de Capsoul en Supabase/Postgres:
  tablas, claves, índices, restricciones, transacciones, migraciones en
  supabase/migrations o consultas con impacto en rendimiento.
---
# Capsoul · SQL en Supabase/Postgres

Usar cuando se cree o cambie el modelo de datos de Capsoul (usuarios, cápsulas, elementos, momentos,
retos, herencias…), se escriba una migración o se revise una consulta.

## Convenciones de nombres (obligatorias)
1. Todo en español, `snake_case`, sin tildes ni ñ: `usuarios`, `capsulas`, `fecha_apertura`, `nombre_visible`.
2. Tablas en plural (`capsulas`); columnas en singular. Clave primaria `id`; claves foráneas `<entidad_singular>_id`
   (`capsula_id`, `usuario_id`). Marcas de tiempo `creado_en` / `actualizado_en` (`timestamptz`).
3. Restricciones con nombre explícito: `<tabla>_<columna>_check`, `<tabla>_<columna>_fkey`, índices
   `<tabla>_<columna>_idx`. Tipos enumerados: `estado_capsula`, `tipo_elemento`.
4. Todo vive en el esquema `public` salvo funciones internas privilegiadas, que van en un esquema no expuesto
   (`privado`).

## Diseño (normalización e integridad)
1. Normalizar hasta 3FN; desnormalizar solo con una razón medida y documentada.
2. Claves primarias `uuid` (`gen_random_uuid()`) para entidades expuestas a la app; `usuarios.id` es el mismo
   `uuid` de `auth.users(id)` con `on delete cascade` (referenciar solo la PK de tablas gestionadas por Supabase).
3. Toda FK con `on delete` explícito (`cascade` si el hijo no tiene sentido sin el padre, `restrict` o `set null`
   en otro caso) y **un índice en cada columna FK** (Postgres no lo crea solo).
4. Reglas de negocio simples en la base: `not null`, `check` (longitudes, rangos, "exactamente un padre"),
   `unique`, enums. No confiar solo en validaciones de la app.
5. `timestamptz` siempre (nunca `timestamp` sin zona); guardar en UTC y convertir en la app.
6. Tipos ajustados: `text` + `check (char_length(...) <= n)` en vez de `varchar(n)`; `bigint` para bytes;
   `numeric` para dinero; `jsonb` solo para datos realmente semiestructurados.
7. Trigger genérico `actualizado_en` (`before update`) en tablas mutables.

## Transacciones y ACID
1. Cada migración es atómica: `begin; … commit;` (o confiar en que la CLI la ejecuta en una transacción) y debe
   poder aplicarse de cero sin errores.
2. Operaciones de varias filas que deben ser consistentes (crear cápsula + elementos + destinatarios) van en una
   sola transacción: función `plpgsql` invocada por RPC o Edge Function, no varias llamadas sueltas desde la app.
3. Usar el nivel de aislamiento por defecto (`read committed`) y `select … for update` o restricciones `unique`
   para evitar carreras; no subir el aislamiento sin necesidad.
4. Evitar transacciones largas y DDL bloqueante en tablas grandes (`create index concurrently` fuera de
   transacción cuando aplique).

## Migraciones versionadas
1. Una carpeta: `supabase/migrations/<AAAAMMDDHHMMSS>_<descripcion_en_snake_case>.sql`, generadas con
   `supabase migration new <nombre>`.
2. **Nunca** editar una migración ya aplicada en un entorno compartido: crear otra nueva.
3. Cada migración que crea una tabla habilita RLS y define sus políticas en el mismo archivo
   (ver `capsoul-supabase-auth-rls`).
4. Probar en local (`supabase db reset` contra el stack local) antes de proponer `supabase db push`.
5. **Aplicar migraciones a un proyecto remoto requiere aprobación previa del PO** con el comando exacto
   (ver `capsoul-mcp`).

## Índices y rendimiento
1. Indexar columnas de FK, de filtros frecuentes y de políticas RLS.
2. Índices compuestos en el orden de la consulta (igualdad primero, rango después); índices parciales para
   subconjuntos calientes (p. ej. `where estado = 'sellada'`).
3. Paginar con cursores (`where creado_en < $1 order by creado_en desc limit n`), no con `offset` grandes.
4. Revisar planes con `explain analyze` cuando una consulta crezca.

## Lista de revisión
- Nombres en español snake_case y restricciones con nombre
- Cada FK con `on delete` e índice
- RLS habilitado y políticas en la misma migración
- Trigger `actualizado_en` donde aplica
- Migración nueva (no editada) y probada en local

## Fuentes
- Supabase Agent Skills, `supabase-postgres-best-practices`: https://github.com/supabase/agent-skills/blob/main/skills/supabase-postgres-best-practices/SKILL.md
- Supabase, "AI Skills": https://supabase.com/docs/guides/ai-tools/ai-skills
- Supabase, "Database migrations": https://supabase.com/docs/guides/deployment/database-migrations
- Supabase, "User management" (tabla de perfiles con FK a `auth.users`): https://supabase.com/docs/guides/auth/managing-user-data
- PostgreSQL, "Constraints" y "Indexes": https://www.postgresql.org/docs/current/ddl-constraints.html , https://www.postgresql.org/docs/current/indexes.html
- PostgreSQL, "Transaction Isolation": https://www.postgresql.org/docs/current/transaction-iso.html
