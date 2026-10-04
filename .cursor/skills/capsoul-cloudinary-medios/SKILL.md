---
name: capsoul-cloudinary-medios
description: >-
  Usar cuando se suban, transformen, muestren o borren medios de Capsoul
  (foto, video, audio) en Cloudinary, o cuando se guarden sus metadatos en
  Postgres (tabla de elementos).
---
# Capsoul · Medios en Cloudinary

Cloud name: `dee3zdenh` (plan Free). Los archivos viven en Cloudinary; Postgres guarda solo referencias.

## Reglas duras
1. **El API secret nunca va en la app** (ni en `--dart-define`): las firmas se generan en una Supabase Edge
   Function autenticada que valida el JWT del usuario antes de firmar.
2. Preferir **subida firmada**: la app pide a la Edge Function `{timestamp, signature, api_key, folder,
   public_id}` y sube directo a `https://api.cloudinary.com/v1_1/dee3zdenh/<tipo>/upload`. La firma vale una
   hora y debe cubrir exactamente los parámetros enviados.
3. Si se usa un **preset unsigned** (solo prototipos), restringirlo en el preset: `allowed_formats`,
   `max_file_size`, `disallow_public_id`, carpeta fija y transformación entrante; su nombre es público.
4. Carpetas por usuario y entidad: `capsoul/usuarios/<uid>/capsulas/<capsula_id>/…`. La carpeta la fija el
   servidor (firma), no el cliente.
5. Contenido sellado: entregar con tipo `authenticated` o `private` y URLs firmadas generadas por el servidor
   solo cuando la política lo permite (`fecha_apertura <= now()`); no confiar en URLs "difíciles de adivinar".
6. En Postgres guardar solo `cloudinary_public_id`, `url` (o `secure_url`), `tipo`, `formato`, `bytes`,
   `duracion`, `ancho`/`alto` si aplica; nunca el binario.
7. Borrar en Cloudinary (llamada firmada desde el servidor) cuando se borra el elemento o la cápsula, o
   encolar la limpieza.

## Transformaciones y rendimiento
1. Pedir derivados con `f_auto,q_auto` y tamaño del contenedor (`w_<n>`, `c_fill`) para miniaturas.
2. Video/audio: transformaciones entrantes o `eager` para normalizar duración/bitrate; en el plan Free vigilar
   créditos de transformación y almacenamiento.
3. Comprimir en el dispositivo antes de subir (imagen/video) y mostrar progreso; validar tamaño y formato antes.

## Lista de revisión
- Ningún secreto de Cloudinary en el repo ni en el binario
- Firma o preset restringido; carpeta por usuario
- Metadatos guardados en Postgres con RLS
- Contenido sellado no descargable antes de tiempo

## Fuentes
- Cloudinary, "Upload presets" (seguridad de presets unsigned): https://cloudinary.com/documentation/upload_presets
- Cloudinary, "Generating authentication signatures": https://cloudinary.com/documentation/authentication_signatures
- Cloudinary, "Client-side uploading": https://cloudinary.com/documentation/client_side_uploading
- Cloudinary, parámetros permitidos en subidas unsigned: https://cloudinary.com/documentation/ts_unsupported_parameters_in_unsigned_uploads
- Cloudinary, "Media access control" (authenticated/private): https://cloudinary.com/documentation/control_access_to_media
- Supabase, "Edge Functions": https://supabase.com/docs/guides/functions
