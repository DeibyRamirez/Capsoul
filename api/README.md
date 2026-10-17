# Capsoul API (VPS)

API HTTP documentada con OpenAPI 3.0. Reemplaza las Edge Functions de Supabase cuando `BACKEND=vps`.

## Contrato

- [`openapi.yaml`](openapi.yaml) — fuente de verdad del contrato Swagger.
- UI Swagger: `http://localhost:8080/docs` al levantar el servidor.

## Desarrollo local

```bash
cd api
dart pub get
dart run bin/server.dart
```

Variables de entorno:

| Variable | Descripción |
|---|---|
| `PORT` | Puerto HTTP (default `8080`) |
| `DATABASE_URL` | Postgres para validar permisos RLS |
| `CLOUDINARY_*` | Credenciales de Cloudinary (solo servidor) |
| `JWT_SECRET` | Firma de tokens en modo VPS |

## Endpoints principales

| Método | Ruta | Equivalente Supabase |
|---|---|---|
| POST | `/v1/medios/firmar-subida` | Edge Function `firmar-subida` |
| POST | `/v1/medios/firmar-entrega` | Edge Function `firmar-medio` |
| POST | `/v1/auth/registro` | Supabase Auth + trigger perfil |
| POST | `/v1/auth/iniciar-sesion` | Supabase Auth |

La app Flutter consume estos endpoints vía `ClienteFuncionesHttp` y `ClienteAutenticacionJwt` cuando `BACKEND=vps`.
