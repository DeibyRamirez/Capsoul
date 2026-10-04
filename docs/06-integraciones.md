# Capsoul · Integraciones externas

## Resumen

| Servicio | Uso en Capsoul | Acceso desde la app |
|---|---|---|
| **Supabase** | Auth, Postgres, RLS, RPC, Edge Functions | `supabase_flutter` + JWT del usuario |
| **Cloudinary** | Almacén de fotos, video y audio | Subida firmada; entrega `authenticated` |
| **Firebase** | Solo FCM (push) | `firebase_core`, `firebase_messaging` |
| **Resend** | SMTP para Auth y correos de aviso | Solo servidor (Supabase / Edge Functions) |

## Supabase

- **Proyecto:** `capsoul` (ref `mslcdvcmfuqopfwojxvt`, us-east-1).
- **Cliente Flutter:** clave **anon/publishable** vía `--dart-define-from-file=env/dev.json`.
- **Nunca en el cliente:** `service_role`, `sb_secret_`, secretos de Edge Functions.

### Edge Functions desplegadas

| Función | Rol |
|---|---|
| `firmar-subida` | Firma de subida a Cloudinary (`type=authenticated`) |
| `firmar-medio` | URLs temporales si RLS lo permite |
| `enviar-avisos` | Pendiente: consume `notificaciones` y envía FCM/correo |

### Migraciones

Ver [`supabase/migrations/`](../supabase/migrations/) y [`modelo_er.md`](modelo_er.md).

## Cloudinary

- **Cloud:** `dee3zdenh` (plan Free).
- En Postgres solo se guarda `cloudinary_public_id` y metadatos.
- Miniaturas: derivadas *eager* en la subida (no transformaciones al vuelo en `authenticated`).

## Firebase (FCM)

- **Proyecto:** `capsoul-ebea3` (plan Spark).
- **Arranque:** `lib/nucleo/firebase/arranque_firebase.dart` + `servicio_notificaciones_push.dart`.
- **Plataformas:** token solo en Android/iOS; en desktop/web se omite sin error.
- **Pendiente:** guardar token en tabla `dispositivos_push` tras login.
- **Archivos nativos:** `google-services.json`, `GoogleService-Info.plist`, `firebase_options.dart`.

## Resend (correo)

- Remitente: `send.cheiviz.com`.
- Configurado en Supabase Auth (SMTP) y secretos de `enviar-avisos`.
- La app **no** contiene la API key.
- Plantillas HTML de Auth (confirmación, magic link, restablecer contraseña, etc.): [`supabase/email-templates/`](../supabase/email-templates/README.md).

## Configuración local del desarrollador

1. Copiar `env/dev.json.example` → `env/dev.json` (ignorado por git).
2. Rellenar `SUPABASE_URL` y `SUPABASE_ANON_KEY`.
3. Ejecutar con `--dart-define-from-file=env/dev.json` (perfil VS Code `Capsoul (dev)`).

## Herramientas de desarrollo

| Herramienta | Uso |
|---|---|
| Flutter 3.47+ / Dart 3.13+ | Framework |
| `flutter analyze` / `flutter test` | Calidad antes de commit |
| GitHub Actions / Codemagic | CI (iOS) |
| Linear / ClickUp | Backlog (skill `capsoul-mcp`) |
| Supabase MCP | Lecturas y cambios con aprobación PO |
