# Capsoul · Migraciones de base de datos

## Fuente de verdad

Las migraciones SQL viven en [`supabase/migrations/`](../supabase/migrations/). Son PostgreSQL estándar (tablas, RLS, funciones `privado`, RPC).

## Catálogo (orden de aplicación)

| Archivo | Contenido |
|---------|-----------|
| `20261002000001` | Modelo inicial v1.3 |
| `20261002000002` | `pg_cron` + trabajos (liberar cápsulas, herencias; job 3 avisos) |
| `20261003000003` | Límites de medios |
| `20261004000004` | Recuerdos y momentos |
| `20261005000005` | Tipo elemento `musica` + columnas `musica_*` |
| `20261006000006` | `musica_enlace_deezer` |
| `20261007000007` | Grants de columnas |
| `20261008000008` | Pendientes de borrado de medio |
| `20261009000009` | Amistad y compartir (enlaces) |
| `20261010000010` | `nombre_usuario` único |
| `20261011000011` | Enum `completado` en retos |
| `20261011000012` | Retos globales y semillas |
| `20261016000013` | Foto de perfil en amigos |
| `20261016000014` | Legado: vínculos cápsulas y RPC |
| `20261016000015` | `musica_preview_proveedor` |

El estado **aplicado en remoto** puede ir por detrás del repo; usar `supabase migration list` antes de cada release.

## Aplicar en Supabase Cloud

### Comando por defecto

```bash
supabase db push
```

O vía Management API / panel de Supabase.

### Cron parcial y música

Orden recomendado (requiere aprobación del PO para el entorno remoto):

1. **Extensiones:** Dashboard → Database → Extensions → activar `pg_cron` y `pg_net`.
2. **Cron (jobs 1–2):** SQL Editor → ejecutar [`infra/scripts/aplicar_cron_parcial_capsoul.sql`](../infra/scripts/aplicar_cron_parcial_capsoul.sql). Comprobar con [`verificar_cron_capsoul.sql`](../infra/scripts/verificar_cron_capsoul.sql).
3. **Historial CLI:**

   ```powershell
   supabase migration repair 20261002000002 --status applied
   supabase migration list
   ```

4. **Música:** migración `000005` añade el enum `musica` **fuera** del `begin`/`commit` (PostgreSQL error `55P04` si se hace en la misma transacción).
5. **Spotify:** `supabase secrets set SPOTIFY_CLIENT_ID=... SPOTIFY_CLIENT_SECRET=...` y `supabase functions deploy buscar-musica`.
6. **Avisos:** `supabase functions deploy enviar-avisos` y activar job 3 solo con Vault (`project_url`, `llave_cron`) configurado.

El archivo [`20261002000002_capsoul_programar_trabajos.sql`](../supabase/migrations/20261002000002_capsoul_programar_trabajos.sql) del repo **incluye** el job 3; no ejecutes el script entero en remoto hasta tener `enviar-avisos` desplegada.

## Aplicar en VPS (PostgreSQL propio)

1. Instalar [dbmate](https://github.com/amacneil/dbmate).
2. Sincronizar SQL desde Supabase (`infra/scripts/sincronizar_migraciones.ps1` o `.sh`).
3. `export DATABASE_URL=...` y `dbmate -d infra/migraciones/db up`.

## Notas al migrar fuera de Supabase

- Los triggers sobre `auth.users` deben reemplazarse por lógica en la API (`api/`) o un esquema de usuarios propio.
- `pg_cron`, `pg_net` y Vault de Supabase requieren alternativas en el VPS (cron del sistema, API de avisos).
- PostgREST y RLS siguen funcionando si el JWT expone el claim que `auth.uid()` espera.

## App Flutter

La app no ejecuta migraciones. Solo consume PostgREST vía `ClientePostgrest` configurado en `--dart-define`:

- `BACKEND=supabase` (por defecto)
- `BACKEND=vps` + `POSTGREST_URL` + `API_BASE_URL`
