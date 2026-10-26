# Avisos push (DEV-100) · despliegue

Guía para el PO. El código ya está en el repo. **No despliega solo:** hay que cargar secretos, aplicar la migración `000018` y desplegar la función. Nada de esto va en git.

Android es el envío que llega hoy. iOS guarda el token y el mensaje ya trae bloque `apns`, pero la entrega real espera una cuenta de Apple y APNs en el proyecto de Firebase.

La liberación de la cápsula no espera a FCM. `privado.liberar_capsulas_vencidas()` deja la fila en `notificaciones` y sigue. Un minuto después el cron llama a `enviar-avisos`. Si FCM falla, el aviso se reintenta (máximo 5) sin volver a mandar los tokens que ya salieron y sin tocar la cápsula.

## 1. Secretos de la función

En Firebase: Configuración del proyecto → Cuentas de servicio → Generar clave privada nueva. Del JSON se usan tres campos. El archivo no se sube al repo.

| Secreto de Supabase | De dónde sale |
|---|---|
| `FCM_PROJECT_ID` | `project_id` del JSON |
| `FCM_CLIENT_EMAIL` | `client_email` del JSON |
| `FCM_PRIVATE_KEY` | `private_key` del JSON (PEM PKCS#8). Si se pega en una sola línea, los saltos van como `\n` |
| `LLAVE_CRON` | Una cadena larga inventada solo para el cron. La misma se carga en el Vault como `llave_cron` |
| `RESEND_API_KEY` | Ya usada para el correo. Si falta, el push sigue; el correo de destinatario externo no |
| `RESEND_FROM` | Opcional. Si no está: `Capsoul <avisos@capsoul.app>` |

No hace falta `FCM_SERVER_KEY`. Ese era el HTTP legacy y la función ya no lo usa.

`SUPABASE_URL` y `SUPABASE_SERVICE_ROLE_KEY` los inyecta Supabase al desplegar. No se copian a mano.

Ejemplo (en la máquina del PO, con la CLI enlazada al proyecto):

```bash
supabase secrets set \
  FCM_PROJECT_ID="capsoul-ebea3" \
  FCM_CLIENT_EMAIL="firebase-adminsdk-XXXX@capsoul-ebea3.iam.gserviceaccount.com" \
  FCM_PRIVATE_KEY="$(cat cuenta-fcm.json | jq -r .private_key)" \
  LLAVE_CRON="$(openssl rand -base64 32)" \
  RESEND_API_KEY="re_..."
```

Guarda el valor de `LLAVE_CRON`: el paso del Vault usa el mismo texto.

## 2. Desplegar la función

`supabase/config.toml` ya tiene `verify_jwt = false` para `enviar-avisos`. La puerta es el header `x-llave-cron`, no el JWT del usuario.

```bash
supabase functions deploy enviar-avisos
```

## 3. Vault

En el SQL Editor (una vez, nunca en una migración del repo):

```sql
select vault.create_secret('https://<ref>.supabase.co', 'project_url');
select vault.create_secret('<el mismo texto de LLAVE_CRON>', 'llave_cron');
```

`<ref>` es el id del proyecto (`mslcdvcmfuqopfwojxvt` en el entorno actual). Sin barra final, o con ella: la función la recorta.

Si estos nombres no están, el job `capsoul-enviar-avisos` termina sin error y sin llamar a la red.

## 4. Migración 000018

Archivo: `supabase/migrations/20261026000018_capsoul_enviar_avisos.sql` (espejo en `infra/migraciones/sql/`).

Hace tres cosas:

- Columna `notificaciones.reclamado_en` y tabla `notificacion_entregas` (un resultado por token).
- `public.reclamar_avisos` / `privado.reclamar_avisos`: toma un lote con `FOR UPDATE SKIP LOCKED`. Dos cron solapados no se llevan la misma fila. Un reclamo de más de 5 minutos se puede volver a tomar (por si el worker se cayó).
- Sustituye el job de cada minuto. El comando solo ejecuta `select privado.invocar_enviar_avisos();`. La URL y la llave se leen del Vault dentro de la función.

Aplicarla en el remoto es un cambio de entorno y queda para cuando el PO lo apruebe. En local, `bash supabase/pruebas/ejecutar.sh`.

## 5. Probar con un aviso

Con la app Android instalada, sesión iniciada y el permiso de notificaciones aceptado (Android 13+), el token queda en `dispositivos_push`.

Inserta un aviso de una cápsula que ya exista y cuyo destinatario seas tú (el `usuario_id` de la fila). `referencia_id` es el id de la cápsula: el texto del push usa su título.

```sql
insert into public.notificaciones (
  usuario_id, canal, tipo, referencia_id, titulo, cuerpo
) values (
  '<uuid del usuario>',
  'push',
  'capsula_liberada',
  '<uuid de la cápsula>',
  'Tienes una cápsula nueva',
  'Una cápsula del tiempo acaba de abrirse para ti.'
);
```

El título y el cuerpo guardados los reescribe la función. El teléfono debe mostrar «Tienes una cápsula nueva» y el cuerpo `«título de la cápsula» ya se puede abrir.` Al tocarlo se abre esa cápsula (`capsoul://capsula/<id>`).

No hace falta esperar al minuto. Con la misma llave:

```bash
curl -sS -X POST "https://<ref>.supabase.co/functions/v1/enviar-avisos" \
  -H "Content-Type: application/json" \
  -H "x-llave-cron: <LLAVE_CRON>" \
  -d '{"origen":"prueba"}'
```

Respuesta esperada: `{"procesadas":1,"enviadas":1,"fallidas":0}`. Sin el header, o con otra llave, responde `401`.

Si FCM dice `UNREGISTERED` o `INVALID_ARGUMENT`, esa fila desaparece de `dispositivos_push` y no se reintenta. Otro error deja el aviso en `pendiente` y la siguiente pasada solo vuelve a enviar los tokens que fallaron.

## 6. Qué mira el cliente Android

- Permiso `POST_NOTIFICATIONS` en Android 13+ (lo pide la actividad antes de guardar el token).
- Canal `capsoul_avisos` con importancia alta. FCM lo usa en segundo plano y con la app cerrada; en primer plano la app muestra el mismo canal.
- Al tocar, se abre la cápsula. El token nuevo (rotación de FCM) se vuelve a guardar en `dispositivos_push`.

Los tipos `solicitud_amistad`, `herencia_liberada`, `herencia_en_verificacion` y `reto` ya tienen plantilla y ruta `capsoul://`. Cuando esos eventos inserten la fila, el mismo cron los envía.
