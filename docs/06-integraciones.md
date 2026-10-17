# Capsoul · Integraciones externas

## Resumen

| Servicio | Uso en Capsoul | Acceso desde la app |
|---|---|---|
| **Supabase** | Auth, Postgres, RLS, RPC, Edge Functions | `supabase_flutter` + JWT del usuario |
| **Cloudinary** | Almacén de fotos, video y audio | Subida firmada; entrega `authenticated` |
| **Spotify Web API** | Catálogo y previews de 30 s para el elemento `musica` | Edge Function `buscar-musica` (Client Credentials; secretos solo en servidor) |
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
| `firmar-medio` | URLs temporales (`elemento_ids`, `avatar_perfil`, `avatares_usuario_ids`) |
| `enviar-avisos` | En repo; desplegar y enlazar job 3 de cron (`verify_jwt = false`, apikey de servicio) |
| `buscar-musica` | Búsqueda de pistas Spotify (`preview_url`, metadatos, enlaces) |

### Migraciones

Ver [`supabase/migrations/`](../supabase/migrations/) y [`modelo_er.md`](modelo_er.md).

## Spotify (catálogo y búsqueda)

Resumen para producto y licencias: [08-musica-producto-y-licencias.md](08-musica-producto-y-licencias.md).

- La app **no** usa la sesión Premium del usuario para buscar: la Edge Function `buscar-musica` usa **Client Credentials** (`SPOTIFY_CLIENT_ID` / `SPOTIFY_CLIENT_SECRET` en secretos de Supabase).
- En **modo desarrollo** del Dashboard de Spotify, la cuenta **dueña de la app** debe tener **Premium** activo; si no, `/v1/search` puede responder `403`.
- Parámetro `limit` en búsqueda: máximo **10** por petición (límite de Spotify en development mode desde 2026). La función y el cliente envían hasta 10 resultados.
- Reproducción en la app: preview de ~30 s (`preview_url`); pista completa vía enlaces externos (Spotify, Deezer, YouTube) con `url_launcher`.
- Despliegue: `supabase secrets set SPOTIFY_CLIENT_ID=... SPOTIFY_CLIENT_SECRET=...` y `supabase functions deploy buscar-musica` (ver [`migraciones.md`](migraciones.md)).
- **Producción:** solicitar revisión y cuotas en Spotify Developer para no depender del modo development ni del Premium del dueño de la app.

## Deezer (fallback de preview)

- Si Spotify devuelve `preview_url` vacío, la Edge Function `buscar-musica` consulta la API pública `https://api.deezer.com/search` (sin token) y rellena `previewUrl` y, si hay match, `enlaceDeezer` (URL de pista).
- Metadatos y enlaces del recuerdo siguen siendo **Spotify** (`musica_proveedor = spotify`); solo el MP3 de 30 s puede provenir de Deezer (`previewProveedor: deezer` en la respuesta de búsqueda). En Postgres: columna opcional `musica_enlace_deezer`.
- Límites en servidor: hasta 5 fallbacks Deezer por búsqueda, timeout 3 s por petición.
- La app reproduce la URL con `just_audio` (sin SDK Deezer). En UI: «Vista previa (Deezer)» cuando aplica.
- **Coste:** la API pública no factura por uso; existe cuota de consultas (ver [FAQs desarrolladores Deezer](https://support.deezer.com/hc/en-gb/articles/360011538897-Deezer-FAQs-For-Developers)).
- **Legal / producción:** los [términos de desarrolladores](https://developers.deezer.com/termsofuse) limitan el uso gratuito de la API a fines **no comerciales**; una app comercial en tiendas puede requerir acuerdo con [Deezer for Partners](https://support.deezer.business/). Capsoul solo reproduce extracts de 30 s en app y abre la pista completa en la app/web de Deezer (no re-streaming). Opción futura: flag en `buscar-musica` para desactivar fallback Deezer hasta tener asesoría legal.

## YouTube y YouTube Music (enlaces de búsqueda)

- Sin YouTube Data API: la app abre búsquedas con `artista + título`:
  - **YouTube Music:** `music.youtube.com/search?q=...`
  - **YouTube (video):** `youtube.com/results?search_query=...`
- No se guarda `video_id` en Postgres.
- Columna opcional `musica_preview_proveedor` (`spotify` | `deezer`) para saber el origen del clip de 30 s al reabrir recuerdos.

## Cloudinary

- **Cloud:** `dee3zdenh` (plan Free).
- En Postgres solo se guarda `cloudinary_public_id` y metadatos.
- Miniaturas: derivadas *eager* en la subida (no transformaciones al vuelo en `authenticated`).
- Avatar de perfil: checklist de BD + `firmar-medio` en [verificacion-avatar-perfil.md](verificacion-avatar-perfil.md).
- Tras cambios en `transformaciones_medios.ts`, redesplegar (con aprobación del PO):

```bash
supabase functions deploy firmar-medio
supabase functions deploy firmar-subida
```

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

## Medios en el dispositivo (cliente)

| Paquete | Uso |
|---|---|
| `camera` / `record` | Captura foto, video y nota de voz |
| `image_picker` | Galería: fotos y videos |
| `file_picker` | Archivos de audio del dispositivo |

Permisos, privacidad y tiendas: [10-permisos-dispositivo-y-privacidad.md](10-permisos-dispositivo-y-privacidad.md).

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
