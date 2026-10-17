# Capsoul · Enlaces HTTPS (fase 2, post-tiendas)

> Estado: **planificado**. La app ya soporta fase 1 (`capsoul://`) en `lib/nucleo/enlaces/`.

## Objetivo

Mismas rutas de producto que en fase 1, pero con URLs compartibles en navegador y recuperación tras instalar desde Play/App Store.

## Rutas públicas sugeridas

| Ruta web | Equivalente app | Acción |
|----------|-----------------|--------|
| `https://{dominio}/c/{capsulaId}` | `capsoul://capsula/{id}` | Abrir detalle si sesión + destinatario |
| `https://{dominio}/i/{token}` | `capsoul://amistad/{token}` | Canje de invitación tras auth |
| `https://{dominio}/descargar` | — | Landing con enlaces a tiendas |

## Infraestructura

1. **Hosting estático** de la landing (dominio del PO).
2. **Android App Links:** `/.well-known/assetlinks.json` con SHA-256 del certificado de firma.
3. **iOS Universal Links:** `apple-app-site-association` en el dominio.
4. **go_router:** mismas rutas que resuelven `EscuchaEnlacesApp` hoy (añadir `GoRoute` para paths `/c/:id` y `/i/:token` si se usa un solo dominio con path).
5. **Deferred deep linking (opcional):** Branch.io o página que guarde `?capsula=` / `?invite=` en localStorage y la primera apertura de la app lea query + cola post-login.

## Criterios de aceptación (cuando se implemente)

- Enlace HTTPS en WhatsApp abre la app instalada en la ruta correcta.
- Usuario sin app llega a landing, instala, registra y recupera invitación o ve «Para mí» según el caso.
- No se expone acceso a cápsulas sin fila en `capsula_destinatarios` (política friends_only).

## Referencias en repo

- Fase 1: `docs/04-flujos-criticos.md` §4.3
- Android: `android/app/src/main/AndroidManifest.xml` (intent-filters actuales solo `capsoul://`)
