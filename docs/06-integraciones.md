# Capsoul · Integraciones externas

## Resumen

| Servicio | Uso en Capsoul | Acceso desde la app |
|---|---|---|
| **Supabase** | Auth, Postgres, RLS, RPC, Edge Functions | `supabase_flutter` + JWT del usuario |
| **Cloudinary** | Almacén de fotos, video y audio | Subida firmada; entrega `authenticated` |
| **Deezer (API pública)** | Catálogo y previews de 30 s del elemento `musica` | La app llama `api.deezer.com` directo. `buscar-musica` hace la misma búsqueda, sin secretos de catálogo, y la app no la invoca |
| **Spotify** | Botón «buscar en Spotify» y recuerdos antiguos | Solo enlaces externos. Sin credenciales de catálogo |
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
| `enviar-avisos` | Push FCM HTTP v1 y correo Resend. `verify_jwt = false`; header `x-llave-cron`. Guía: [avisos-push-despliegue.md](avisos-push-despliegue.md) |
| `buscar-musica` | Búsqueda en Deezer (`proveedor: deezer`, máx. 10). `verify_jwt = true`. La app no la invoca |

### Migraciones

Ver [`supabase/migrations/`](../supabase/migrations/) y [`modelo_er.md`](modelo_er.md).

## Deezer (catálogo y búsqueda)

Resumen para producto y licencias: [08-musica-producto-y-licencias.md](08-musica-producto-y-licencias.md).

- La app busca con `GET https://api.deezer.com/search` y refresca el preview con `GET https://api.deezer.com/track/<id>` (`RepositorioMusicaDeezer`). No invoca la Edge Function.
- `buscar-musica` repite esa búsqueda para quien la llame con JWT (`verify_jwt = true` en `supabase/config.toml`). Cuerpo `{ consulta, limite, mercado }`; respuesta `{ resultados }` con `proveedor: "deezer"`, `previewUrl`, `previewProveedor: "deezer"` si hay clip, `enlaceDeezer`, `urlCompleta` y `uriProfundo` (`deezer://www.deezer.com/track/<id>`). Máximo **10** resultados. `mercado` se acepta y no se reenvía: la API pública no filtra por país.
- No hay secretos de catálogo ni respaldo a otro proveedor. El despliegue de la función, si se hace, requiere aprobación del PO.
- Reproducción en la app: preview de ~30 s con `just_audio` (sin SDK). La URL caduca y no se guarda. Pista completa: «Abrir en Deezer», «Buscar en Spotify» y YouTube (`url_launcher`).
- Las filas antiguas con `musica_proveedor = spotify` siguen abriendo la pista guardada en Spotify.
- **Coste:** la API pública no factura por uso; existe cuota de consultas (ver [FAQs desarrolladores Deezer](https://support.deezer.com/hc/en-gb/articles/360011538897-Deezer-FAQs-For-Developers)).
- **Legal / producción:** los [términos de desarrolladores](https://developers.deezer.com/termsofuse) limitan el uso gratuito de la API a fines **no comerciales**; una app comercial en tiendas puede requerir acuerdo con [Deezer for Partners](https://support.deezer.business/). Capsoul solo reproduce extracts de 30 s en app y abre la pista completa en la app/web de Deezer (no re-streaming).

## Spotify (enlaces y recuerdos antiguos)

- No se usa la Web API de Spotify ni credenciales de aplicación.
- El botón «Buscar en Spotify» abre `https://open.spotify.com/search/...`. Si el recuerdo ya era de Spotify, se abre el enlace guardado.
- `musica_preview_proveedor` puede seguir siendo `spotify` en filas antiguas.

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
- **API:** HTTP v1 desde `enviar-avisos` (cuenta de servicio). No se usa el endpoint legacy `fcm/send`.
- **Arranque:** `lib/nucleo/firebase/arranque_firebase.dart` + `servicio_notificaciones_push.dart`.
- **Plataformas:** el token se guarda en `dispositivos_push` en Android e iOS. Desktop y web se omiten. El envío que llega al teléfono, por ahora, es Android; iOS queda preparado para cuando haya cuenta de Apple y APNs.
- **Canal Android:** `capsoul_avisos` (importancia alta) y permiso `POST_NOTIFICATIONS` en Android 13+.
- **Archivos nativos:** `google-services.json`, `GoogleService-Info.plist`, `firebase_options.dart`.
- **Despliegue:** [avisos-push-despliegue.md](avisos-push-despliegue.md).

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
