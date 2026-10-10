# Capsoul · Migraciones de base de datos

## Fuente de verdad

Las migraciones SQL viven en [`supabase/migrations/`](../supabase/migrations/). Son PostgreSQL estándar (tablas, RLS, funciones `privado`, RPC).

## Aplicar en Supabase Cloud

### Estado habitual del proyecto `capsoul`

| Migración | Contenido | Notas |
|-----------|-----------|--------|
| `000001` | Modelo inicial | Aplicada |
| `000002` | `pg_cron` + trabajos | En remoto se aplicó **solo** jobs 1–2 (ver abajo); el job `enviar-avisos` queda para cuando exista la Edge Function |
| `000003`–`000004` | Límites, recuerdos, momentos | Aplicadas |
| `000005` | Elemento `musica` | Pendiente hasta `db push` o SQL manual |

Si `supabase db push` dice que falta insertar `000002` antes de la última migración remota, sigue la sección [Cron parcial y música](#cron-parcial-y-música).

### Comando por defecto

```bash
supabase db push
```

O vía Management API / panel de Supabase, como hasta ahora.

### Cron parcial y música

Orden recomendado (requiere aprobación del PO para el entorno remoto):

1. **Extensiones:** Dashboard → Database → Extensions → activar `pg_cron` y `pg_net`.
2. **Cron (jobs 1–2):** SQL Editor → ejecutar [`infra/scripts/aplicar_cron_parcial_capsoul.sql`](../infra/scripts/aplicar_cron_parcial_capsoul.sql). Comprobar con [`verificar_cron_capsoul.sql`](../infra/scripts/verificar_cron_capsoul.sql).
3. **Historial CLI:**

   ```powershell
   supabase migration repair 20261002000002 --status applied
   supabase migration list
   ```

4. **Música:** `supabase db push` (solo `000005`). La migración `000005` añade el enum `musica` **fuera** del `begin`/`commit` (PostgreSQL error `55P04` si se hace en la misma transacción). Alternativa: SQL Editor + `migration repair 20261005000005`.
5. **Spotify:** `supabase secrets set SPOTIFY_CLIENT_ID=... SPOTIFY_CLIENT_SECRET=...` y `supabase functions deploy buscar-musica`. La cuenta dueña de la app en Spotify Developer debe tener Premium si la app está en development mode; la búsqueda usa `limit` máx. 10.

El archivo [`supabase/migrations/20261002000002_capsoul_programar_trabajos.sql`](../supabase/migrations/20261002000002_capsoul_programar_trabajos.sql) del repo **sigue incluyendo** el job 3; no lo ejecutes entero en remoto hasta tener `enviar-avisos` y secretos en Vault (`project_url`, `llave_cron`). Una migración futura puede añadir solo ese job.

## Aplicar en VPS (PostgreSQL propio)

1. Instalar [dbmate](https://github.com/amacneil/dbmate).
2. Sincronizar SQL desde Supabase:

   ```powershell
   .\infra\scripts\sincronizar_migraciones.ps1
   ```

   ```bash
   ./infra/scripts/sincronizar_migraciones.sh
   ```

3. Definir la URL de conexión:

   ```bash
   export DATABASE_URL="postgres://usuario:clave@host:5432/capsoul?sslmode=disable"
   ```

4. Aplicar:

   ```bash
   dbmate -d infra/migraciones/db up
   ```

   O usar el script todo-en-uno:

   ```bash
   ./infra/scripts/aplicar_migraciones.sh
   ```

## Notas al migrar fuera de Supabase

- Los triggers sobre `auth.users` deben reemplazarse por lógica en la API (`api/`) o un esquema de usuarios propio.
- `pg_cron`, `pg_net` y Vault de Supabase requieren alternativas en el VPS (cron del sistema, API de avisos).
- PostgREST y RLS siguen funcionando si el JWT expone el claim que `auth.uid()` espera.

## App Flutter

La app no ejecuta migraciones. Solo consume PostgREST vía `ClientePostgrest` configurado en `--dart-define`:

- `BACKEND=supabase` (por defecto)
- `BACKEND=vps` + `POSTGREST_URL` + `API_BASE_URL`
