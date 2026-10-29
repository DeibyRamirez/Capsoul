# Capsoul · Permisos del dispositivo y privacidad

Documento interno para desarrollo, política de privacidad y fichas de tienda (Play Data Safety / App Store Privacy). Actualizar cuando cambien permisos o flujos de medios.

## Resumen

Capsoul solo accede al dispositivo cuando el usuario inicia una acción (capturar o elegir archivo). Los archivos elegidos se procesan en el teléfono (compresión/validación) y, si el usuario guarda el recuerdo, se suben a **Cloudinary** asociados a su cuenta **Supabase**. No vendemos ni compartimos medios con terceros con fines publicitarios.

## Permisos por plataforma

| Permiso (Android) | Permiso (iOS) | Cuándo se pide | Finalidad | Datos que salen del dispositivo |
|-------------------|---------------|----------------|-----------|-------------------------------|
| `CAMERA` | `NSCameraUsageDescription` | Tomar foto/video | Captura in-app | Foto o video → Cloudinary (cuenta del usuario) |
| `RECORD_AUDIO` | `NSMicrophoneUsageDescription` | Grabar nota de voz / video con sonido | Captura in-app | Audio → Cloudinary |
| `READ_MEDIA_IMAGES` / galería | `NSPhotoLibraryUsageDescription` | Elegir foto de galería | Importar recuerdo existente | Solo el archivo elegido |
| `READ_MEDIA_VIDEO` | (misma clave galería) | Elegir video | Importar video | Solo el archivo elegido |
| `READ_MEDIA_AUDIO` | Selector de archivos | Elegir audio | Importar nota de voz/archivo | Solo el archivo elegido |
| `READ_EXTERNAL_STORAGE` (API ≤ 32) | — | Galería en Android antiguo | Igual que lectura de medios | Solo el archivo elegido |
| `INTERNET` | Red | Uso normal de la app | Auth, API, subida y reproducción | Tráfico cifrado (HTTPS) |
| `POST_NOTIFICATIONS` (Android 13+) | Alertas | Al iniciar sesión en el teléfono | Avisar cápsula liberada, amistad, legado o reto | Solo el token FCM del dispositivo |

Los plugins `image_picker` y `file_picker` muestran el diálogo del sistema; no usamos `permission_handler` de forma global.

## Flujo de datos (medios)

1. Usuario elige **Capturar** o **Elegir del dispositivo** al crear un recuerdo.
2. Validación local según [`LimitesMedios`](../lib/funcionalidades/elementos/dominio/limites_medios.dart) (tamaño, duración).
3. Subida firmada vía Edge Function `firmar-subida` → Cloudinary (`type=authenticated`).
4. Metadatos en Postgres (`elementos`, RLS por `propietario_id`).

## Retención y borrado

- En servidor: reglas de RLS y borrado de elementos según producto (el usuario puede eliminar recuerdos).
- En dispositivo: caché temporal de compresión y miniaturas; no se indexa toda la galería.

## Cumplimiento (borrador)

- **RGPD / LOPD:** base legal habitual = ejecución del contrato (cuenta) + consentimiento explícito al subir contenido personal; derecho de acceso/borrado vía soporte y funciones de la app.
- **Google Play Data Safety:** declarar recopilación de fotos/videos/audio (usuario proporciona), cifrado en tránsito, no compartido con anunciantes.
- **App Store:** Privacy Nutrition Labels alineadas con la tabla anterior.

## Código relacionado

- Importación: [`importador_medios_dispositivo.dart`](../lib/funcionalidades/elementos/datos/importador_medios_dispositivo.dart)
- Manifiesto Android: [`AndroidManifest.xml`](../android/app/src/main/AndroidManifest.xml)
- iOS: [`Info.plist`](../ios/Runner/Info.plist)
