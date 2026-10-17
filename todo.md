# Capsoul · Tareas de backend pendientes (Linear CAPPSOUL)

> Documento de trabajo. Revisado contra el código local y el remoto (solo lectura) el 2026-10-12, tarde.
> **Hecho en repo (commits locales en `develop`, sin push):** destinatarios múltiples por amistad/@, `listarRecibidas` / UI «Para mí», CRUD de cápsulas (editar con fecha y hora, recuerdos y destinatarios), sesión segura (DEV-97), migraciones 000007–000010, tokens FCM en `dispositivos_push`, CI GitHub Actions, rediseño claro, `flutter analyze` **0 issues**, **245** tests en verde.
> **Remoto verificado (2026-10-12):** `schema_migrations` registra solo 000001–000006, pero los objetos de 000007–000010 ya existen (sin registrar). Funciones desplegadas: `firmar-subida` v2, `firmar-medio` v3, `buscar-musica` v7. Cron: `capsoul-liberar-capsulas` y `capsoul-activar-herencias`; falta `capsoul-enviar-avisos`. Vault vacío.
> **Pendiente:** `enviar-avisos` (fuera de los commits: falta validar la llave del cron y migrar a FCM HTTP v1), procesador de la cola `pendientes_borrado_medio`, UI para editar momentos y recuerdos, marcadores dbmate en las copias de `infra/` de 000007–000009, verificación en dispositivo (video C7).
> No contiene código de implementación: solo describe lo que falta y cita lo que ya existe.

## Contexto común

- **Stack:** Flutter (`supabase_flutter ^2.18.0`, `firebase_messaging ^16.7.0` solo para FCM) + Supabase (proyecto `mslcdvcmfuqopfwojxvt`: Postgres, Auth, RLS, Edge Functions en Deno, pg_cron) + Cloudinary (cloud `dee3zdenh`, entrega `authenticated`, impuesta por CHECK en `elementos.cloudinary_tipo_entrega`).
- **Medios:** subida firmada con la Edge Function `firmar-subida` y lectura firmada con `firmar-medio` (`private_download_url` con `expires_at`: miniatura 7 días, original 24 h).
- **Repo:** `DeibyRamirez/Capsoul`, rama `develop`.
- **Migraciones oficiales:** `supabase/migrations/` (000001 a 000006). Hay una copia en `infra/migraciones/sql/` para dbmate, que se sincroniza con `infra/scripts/sincronizar_migraciones.ps1|.sh`. Toda migración nueva va en ambas, se sincroniza y lleva su prueba en `supabase/pruebas/`.
- **Enum `public.estado_capsula`:** `borrador`, `programada`, `liberada`, `cancelada` (000001, línea 38).
- **Enum `public.tipo_elemento`:** `foto`, `video`, `audio`, `texto`, más `musica` desde la 000005.
- **`capsulas.fecha_apertura`:** ya es `timestamptz` (000001, línea 140).
- **CHECK de `capsulas`:** `capsulas_fecha_requerida` y `capsulas_liberada_coherente`; `estado = 'liberada'` implica `liberada_en` no nulo.
- **verify_jwt:** `supabase/config.toml` tiene `verify_jwt = true` para las tres funciones (`firmar-subida`, `firmar-medio`, `buscar-musica`).

### Cómo probar

- **App:** `flutter test` y `flutter analyze`.
- **SQL:** usar un Postgres local desechable con un esquema `auth` simulado, aplicar las migraciones en orden y luego ejecutar `psql -f supabase/pruebas/pruebas_rls_capsoul.sql` (también `pruebas_limites_medios.sql` y `pruebas_recuerdos_momentos.sql`). Los scripts usan `set role authenticated` y `request.jwt.claim.sub`.
- **Edge Functions:** `deno test` dentro de cada carpeta:
  - `supabase/functions/firmar-medio/firma_entrega_test.ts`
  - `firmar-subida/limites_test.ts`
  - `buscar-musica/deezer_preview_test.ts`

### Reglas

- Código, nombres y commits en español, incluido el tipo (`funcionalidad(...)`, `corrección(...)`).
- Nada de commit, push ni cambios en Supabase, Cloudinary o Firebase sin el sí explícito del PO.
- Las migraciones nuevas van en `supabase/migrations/` con pruebas.
- Sin secretos en la app: el `.env` de la raíz es solo para herramientas. Los secretos de las funciones van en `supabase secrets` y los de cron en Vault.

---

## 1. DEV-97 [BACK-1] Sesión en almacenamiento seguro

**Ya cumplido:** registro, login con confirmación de correo obligatoria, recuperación, perfil, rutas protegidas (`resolverRedireccionAutenticacion`), RLS y `verify_jwt`.

**Estado actual (implementado):**
- `flutter_secure_storage` + `AlmacenamientoSesionAuth` (`LocalStorage`) en Android/iOS vía `arranque_supabase.dart`.
- Migración one-shot desde SharedPreferences (`migracion_sesion_shared_preferences.dart`).
- Pruebas: `test/nucleo/supabase/almacenamiento_sesion_auth_test.dart`.
- Arranque vivo: `main.dart` → `arranque_backend.dart` → `proveedores/supabase/arranque_supabase.dart` (el de `lib/nucleo/supabase/` es re-export).

**Falta (PO / dispositivo):** validar deep links y Keystore tras restore de backup en Android.

**Criterios de aceptación:**
- La sesión no aparece en SharedPreferences.
- El cierre de sesión borra la sesión segura.
- La app arranca con la sesión ya migrada.
- Los deep links `capsoul://auth/confirmar|recuperar` siguen funcionando.

**Riesgos:**
- Keystore se pierde al restaurar un backup en Android.
- La lectura asíncrona en el arranque puede retrasarlo.
- En la web no hay Keychain; mantener el comportamiento por defecto.

---

## 2. DEV-98 [BACK-2] Medios para destinatarios y limpieza de huérfanos

**Corrección del texto del PO:** los destinatarios ya pueden firmar los medios de una cápsula liberada. No hace falta una regla nueva. La cadena actual es esta:

- `supabase/functions/firmar-medio/index.ts`:
  - Valida el `Bearer` con `auth.getUser`.
  - Consulta `elementos` (columnas `id, tipo, cloudinary_public_id, cloudinary_tipo_recurso, cloudinary_version, formato`) con el JWT del usuario, así que **RLS decide** qué se firma.
  - Lo que RLS oculta simplemente no se devuelve.
  - No hay lógica propia de destinatarios.
- Política `elementos_leer`, redefinida en la 000004, línea 27: `propietario_id = auth.uid() or privado.puede_ver_elemento(id)`.
- `privado.puede_ver_elemento` (000001, línea 386) acepta el elemento si está en `capsula_elementos` de una cápsula para la que `privado.puede_ver_capsula` es verdadero.
- `privado.puede_ver_capsula` (000001, línea 323): el autor, o un destinatario (`capsula_destinatarios.usuario_id = auth.uid()`) **solo si `estado = 'liberada'`**.
- `capsula_destinatarios` tiene RLS:
  - `capsula_destinatarios_leer`: el destinatario ve su fila; el autor ve todas.
  - `_crear` y `_eliminar` solo con `privado.capsula_editable_por_mi`.
- Funciones de apoyo: `public.capsulas_recibidas()` (el título solo si está liberada) y `public.marcar_capsula_abierta(p_capsula)`.

**Consecuencia:** el acceso depende del **estado** `liberada`, no de que `fecha_apertura` haya vencido. Mientras nadie libere la cápsula, el destinatario no ve nada aunque la fecha ya haya pasado. Eso es correcto y no conviene abrirlo por fecha.

**Falta:**
1. **Liberación automática.**
   - La función se llama `privado.liberar_capsulas_vencidas()` y existe desde la **000001** (línea 860), no desde la 000002. Hace dos cosas:
     - Pasa a `liberada` (con `liberada_en = now()`) las cápsulas `programada` con `fecha_apertura <= now()`.
     - Inserta en `notificaciones` avisos `capsula_liberada`: `push` si el destinatario es usuario, `correo` si es externo.
   - La **000002** (`20261002000002_capsoul_programar_trabajos.sql`) solo programa tres trabajos:
     - `capsoul-liberar-capsulas`: cada minuto.
     - `capsoul-activar-herencias`: cada hora.
     - `capsoul-enviar-avisos`: cada minuto, por `pg_net`, contra la función `enviar-avisos`.
   - Requisitos de la 000002: extensiones `pg_cron` y `pg_net`, y los secretos `project_url` y `llave_cron` en Vault.
   - Según `Memory.md`, la 000002 está **pendiente de aplicar** (sin verificar en remoto).
   - **Bloqueo:** la Edge Function `enviar-avisos` **no existe en el repo**. Opciones:
     - Aplicar la 000002 solo con los dos primeros trabajos usando `infra/scripts/aplicar_cron_parcial_capsoul.sql`, y verificar con `infra/scripts/verificar_cron_capsoul.sql`.
     - Crear antes `enviar-avisos`.
   - Hay que decidirlo con el PO.
   - Prueba sugerida: un caso en `supabase/pruebas/` que llame a la función como `postgres` y compruebe el estado, `liberada_en`, las filas de `notificaciones` y que el destinatario pase a ver `elementos`.
2. **Limpieza de huérfanos en Cloudinary.** Hoy no existe ningún mecanismo. Hay dos casos:
   - (a) Assets subidos con `firmar-subida` que nunca llegaron a tener fila en `elementos`, porque la subida terminó pero el insert falló o se canceló.
   - (b) Elementos borrados (los borra `RepositorioRecuerdos.eliminar` en `lib/funcionalidades/recuerdos/datos/acceso_tablas_recuerdos.dart:79`, o la cascada al borrar una cuenta) cuyo asset sigue vivo.

   Propuesta, sin código:
   - Una Edge Function o un trabajo programado con el rol de servicio y la Admin API de Cloudinary (listar por prefijo, borrar con `invalidate`).
   - Debe ser idempotente y ejecutarse por lotes.
   - Debe dar un margen de gracia (por ejemplo, 24 h) a los assets recientes, para no romper subidas en curso.
   - Para el caso (b), basta una tabla de "pendientes de borrar" alimentada por un trigger `after delete` en `elementos` (`cloudinary_public_id`, `cloudinary_tipo_recurso`), o comparar el listado de Cloudinary con `elementos`.
   - También hay que cubrir el borrado de una cápsula (ver la sección 3) y la cuota: `privado.bytes_usados` y `privado.validar_cuota_medios` (000003) solo cuentan las filas.
   - Nuevos secretos (Admin API) solo en `supabase secrets`.
3. **Miniatura de video real.** Comprobar en el dispositivo un video subido con su miniatura *eager* (según `firmar-subida/limites.ts`) y la URL firmada que devuelve `firma_entrega.ts`, sobre todo el formato y el `resource_type` `video`. Ampliar `firma_entrega_test.ts` si aparece algún caso nuevo.

**Criterios de aceptación:**
- El destinatario B obtiene las URLs justo después de la liberación y no antes.
- El trabajo de limpieza borra solo los huérfanos y se puede ejecutar dos veces sin errores.
- Las pruebas SQL y `deno test` pasan.

**Riesgos:**
- Si el plan Free pausa el proyecto, pg_cron no corre (decisión D1).
- Un borrado con la Admin API es irreversible.
- `enviar-avisos` sigue sin existir.

---

## 3. DEV-94 [FRONT-3] Backend del CRUD (sin UI)

**Estado de los repositorios:**
- `lib/funcionalidades/capsulas/dominio/repositorio_capsulas.dart`: solo `crearCapsula`, `listarMisCapsulas` y `obtenerCapsula`.
  - `acceso_tablas_capsulas.dart:62` ya tiene un borrado de la fila de `capsulas`, pero no hay un método de edición expuesto en el repositorio.
- `repositorio_momentos.dart`: tiene `crear`, `listar`, `obtener` y `eliminar`; **no tiene editar**.
- `repositorio_recuerdos.dart`: tiene `crear`, `listar`, `obtener`, `contarCapsulasSelladas`, `eliminar` y `leerUsoMedios`; **no tiene editar**.

**Reglas de servidor existentes (nombres reales):**

`capsulas` (000001, líneas 648 a 656; `capsulas_leer` redefinida en la 000004):
- `capsulas_editar`: USING `autor = yo` y estado `borrador` o `programada`; WITH CHECK estado `borrador`, `programada` o `cancelada`.
- `capsulas_eliminar`: **solo** en estado `borrador` o `cancelada`. Una `programada` no se puede borrar directamente: hay que cancelarla primero o cambiar la política.
- Trigger `capsulas_validar` → `privado.validar_capsula()` (línea 516). Para el rol `authenticated`:
  - prohíbe pasar a `liberada` o fijar `liberada_en`;
  - prohíbe cambiar `autor_id`;
  - exige que una `programada` tenga `fecha_apertura` posterior a `now() + 1 minuto`.
- Trigger `capsulas_actualizado` → `privado.marcar_actualizado()`.

Relaciones de la cápsula:
- `capsula_elementos_crear` y `capsula_elementos_eliminar`: con `privado.capsula_editable_por_mi` (autor y estado `borrador` o `programada`). Crear exige además `privado.es_mi_elemento`.
- Máximo de 10 elementos: trigger `capsula_elementos_validar_maximo` (000003).
- `capsula_destinatarios_crear` y `capsula_destinatarios_eliminar`: con `privado.capsula_editable_por_mi`. No hay política UPDATE: editar un destinatario significa borrarlo y volver a insertarlo.

`elementos`:
- `elementos_editar` y `elementos_eliminar`: propietario y `not privado.elemento_entregado(id)`, es decir, que no esté en una cápsula o herencia **liberada**.
- Trigger `elementos_impedir_borrar_en_capsula` (000004, línea 93; error `CAP03`): bloquea el borrado si el recuerdo está en una cápsula `programada` o `liberada`. Por eso "sellada" equivale a `programada` o `liberada`.
- Editar un elemento en una cápsula `programada` sí está permitido hoy. Hay que decidir si debe estarlo.

`momentos`:
- `momentos_editar` y `momentos_eliminar`: solo `autor = yo`.
- Triggers `momentos_validar_portada` y `momento_elementos_quitar_portada` (000004).
- `momento_elementos` no tiene política UPDATE.

GRANT:
- `grant select, insert, update, delete` sobre `capsulas`, `elementos`, `momentos` y otras tablas (000001, línea 759) **sin restringir columnas**.
- Solo `usuarios` limita UPDATE a `nombre_visible`, `foto_public_id` y `perfil_publico`.

**Falta:**
1. Métodos de repositorio, con su acceso a tablas, para:
   - editar una cápsula: `titulo` (1 a 120 caracteres), `mensaje` y `fecha_apertura`, además de añadir o quitar recuerdos y destinatarios;
   - cancelar o eliminar una cápsula;
   - editar un momento (título, visibilidad, portada);
   - editar un recuerdo (`titulo`, `fecha_recuerdo` y los campos `musica_*`).

   Los errores de Postgres (`CAP03`, RLS, CHECK) deben traducirse con `lib/nucleo/supabase/errores_postgrest.dart`.
2. **Una cápsula liberada en solo lectura:** RLS ya lo garantiza (`capsulas_editar`, `capsula_editable_por_mi` y `elemento_entregado`). Solo falta cubrirlo con pruebas.
3. **Restringir el GRANT UPDATE** de `capsulas` a las columnas editables (`titulo`, `mensaje`, `fecha_apertura`, `estado`), y quizá también los de `elementos` y `momentos`, con una migración nueva 000007 y sus pruebas.
4. **Eliminar una cápsula con limpieza de medios:** decidir si los recuerdos sobreviven (lo más probable es que sí, porque son del banco del usuario) y qué pasa con una `programada`: cancelarla y luego borrarla, o ampliar `capsulas_eliminar`. Enlazar con la limpieza de la sección 2.
5. **Fecha con hora:** el tipo ya es `timestamptz`. La hora fija de las 8:00 está en el cliente (`lib/funcionalidades/capsulas/presentacion/pantalla_crear_capsula.dart:84`, `DateTime(..., 8)`).
   - En el backend solo hay que asegurar que el repositorio envíe la fecha en UTC con su desfase (ISO 8601) y la lea en hora local.
   - El cambio del selector es de UI y queda fuera de este documento.
6. **Pruebas:**
   - Repositorio: `test/funcionalidades/{capsulas,momentos,recuerdos}/datos/*_test.dart` con los falsos de `test/ayudantes/`.
   - RLS: ampliar `supabase/pruebas/` con estos casos:
     - editar una cápsula programada: sí;
     - editar una liberada: no;
     - el destinatario intenta editar: no;
     - borrar una programada: no;
     - mover la fecha al pasado: error;
     - quitar un recuerdo de una liberada: no.

**Criterios de aceptación:** los métodos funcionan contra Postgres local, cada caso prohibido devuelve un error traducido y las pruebas pasan.

**Riesgos:**
- Restringir el GRANT puede romper inserciones o actualizaciones existentes, por ejemplo si la app actualiza otras columnas.
- La política `capsulas_editar` deja pasar `cancelada` en WITH CHECK, pero no hay forma de "descancelar".

---

## 4. Otros pendientes de backend (no UI)

- **DEV-100: tokens push.**
  - `lib/nucleo/firebase/servicio_notificaciones_push.dart` obtiene el token FCM y solo lo imprime con `debugPrint`, cosa que conviene quitar porque es un dato sensible.
  - Falta registrarlo en `public.dispositivos_push` (CHECK `plataforma in ('android','ios')`, política `dispositivos_propios` para el propio usuario) cada vez que se actualice el token (`onTokenRefresh`), y borrarlo al cerrar sesión.
  - Falta además la Edge Function `enviar-avisos`, que consume `notificaciones` con `estado = 'pendiente'` y envía por FCM HTTP v1.
- **CHECK de música:** `elementos_musica_coherente` (000005) solo permite datos de música en los tipos `musica` y `foto`, y `elementos_musica_proveedor_valido` solo admite `spotify`.
  - Hay que decidir si los videos, audios o textos con música de fondo deben admitirse.
  - La 000006 solo añade `musica_enlace_deezer`; el proveedor sigue siendo `spotify`.
- **Estado remoto (sin verificar en remoto):**
  - Según `Memory.md`, la 000001, la 000003 y la 000004 están aplicadas, y la 000002 está pendiente.
  - No consta si la 000005 y la 000006 están aplicadas, ni si `buscar-musica`, `firmar-subida` y `firmar-medio` están desplegadas con sus secretos.
  - Hay que confirmarlo con `supabase_migrations.schema_migrations` y la lista de funciones cuando haya un token.
- **Análisis estático:** `flutter analyze` **0 issues** (2026-10-12, post-plan).
  - Warning `unawaited_return_in_try_block` en `lib/funcionalidades/elementos/datos/repositorio_medios_cloudinary.dart:34`.
  - Warning `invalid_visibility_annotation` en `lib/nucleo/infraestructura/proveedores/supabase/cliente_almacenamiento_cloudinary.dart:60`.
  - Cinco infos `prefer_initializing_formals`:
    - `repositorio_medios_cloudinary.dart:15` y `:16`
    - `repositorio_urls_medio_agrupado.dart:18`
    - `proveedores/vps/cliente_funciones_http.dart:17`
    - `test/ayudantes/falsos.dart:391`

  La regla del repo exige 0 issues antes de subir.
- **CI:** `.github/workflows/ci.yml` (Flutter + `deno test` en Edge Functions; SQL en contenedor: pendiente de añadir job Postgres).
- **Proveedor VPS:** documentado como legado en `lib/nucleo/infraestructura/proveedores/vps/README.md`.
- **CHECK música:** decisión documentada en `docs/09-decision-check-musica.md`.

---

## Criterio general de cierre

- Las pruebas pasan: `flutter test`, `deno test` y `supabase/pruebas/*.sql`.
- `flutter analyze` no da issues nuevos.
- Las migraciones están en `supabase/migrations/` y en `infra/migraciones/sql/`.
- No se aplica nada en remoto sin el sí del PO.
- El PO lo prueba en el dispositivo.
