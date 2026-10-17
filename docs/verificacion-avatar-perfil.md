# Verificación: avatar de perfil (Yo)

Checklist cuando la foto está en Cloudinary pero la app queda cargando o no muestra imagen.

## A. Postgres (`usuarios`)

```sql
select id, foto_public_id
from usuarios
where nombre_usuario = 'deiby'; -- o where id = '<uid>';
```

Esperado: `foto_public_id` = `capsoul/usuarios/<uid>/avatar`.

Si es `null` pero el archivo existe en Cloudinary, la app no puede firmar el avatar. Corregir con nueva subida desde la app o, con aprobación del PO:

```sql
update usuarios
set foto_public_id = 'capsoul/usuarios/<uid>/avatar'
where id = '<uid>';
```

## B. Cloudinary

En Media Library, el `public_id` debe coincidir con la columna anterior (recurso `authenticated`).

## C. Edge `firmar-medio`

Con sesión activa (JWT del usuario), invocar la función con cuerpo:

```json
{ "avatar_perfil": true }
```

Respuesta esperada: `medios[0]` con `url` (https), `public_id`, `expira_original` o `expira_en`.

- `medios: []` → `foto_public_id` vacío en BD para ese uid.
- HTTP 422 → función desplegada sin rama `avatar_perfil` (redesplegar desde el repo).
- Sin respuesta / timeout → revisar logs de la función en Supabase.

## D. URL firmada

Abrir `medios[0].url` en el navegador: debe mostrarse la imagen (no 401/404).

## E. Despliegue

Redesplegar `firmar-medio` y `firmar-subida` tras cambios en `transformaciones_medios.ts`. Si el eager de miniatura cambió, volver a subir la foto de perfil una vez.

## F. Migración amigos

Para avatares en la fila «Amigos e invitaciones», aplicar `supabase/migrations/20261016000013_capsoul_amigos_foto_perfil.sql`.
