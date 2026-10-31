# Memory.md — Memoria del proyecto Capsoul

> Este archivo es la fuente de verdad del estado del código. Se **consulta antes** de empezar cualquier tarea
> y se **actualiza al terminarla** (bitácora + estado + pendientes). Mantenerlo corto y al día.

## 1. Proyecto

- **App:** Capsoul — cápsulas del tiempo y legado digital. Slogan: *Pequeñas herencias, grandes recuerdos*.
- **Plataformas:** Android e iOS (Flutter). Identificador: `com.capsoul`. Paquete Dart: `capsoul`.
- **Repo:** https://github.com/DeibyRamirez/Capsoul (antes `Capsould`, GitHub redirige).
- **Ramas:** `main` (estable) · `develop` (integración del sprint).
- **Carpeta local:** `D:\Proyectos\Pasantia\CappSoul\capsould` (el nombre de la carpeta no se cambia).
- **Gestión:** Scrum. Backlog en ClickUp y Linear, lo lleva el agente Capsoul (director de proyecto).

## 2. Reglas de trabajo

1. **Nada de commit ni push sin autorización explícita del PO.** Nunca push a `main`, nunca force-push, no reescribir historia.
2. **Commits 100 % en español**, incluido el tipo: `funcionalidad(...)`, `corrección(...)`, `tarea(...)`,
   `documentación(...)`, `pruebas: ...`, `compilación(...)`, `refactorización(...)`.
3. Antes de subir: `flutter analyze` sin issues y `flutter test` en verde. Si se tocan archivos nativos
   (Info.plist, .cc, .cpp, Gradle), revisar `git diff` a mano y compilar al menos `flutter build apk --debug`.
4. Nada de reemplazos masivos con regex sobre archivos nativos: usar reemplazo literal o editar a mano
   (ver incidente del 2026-09-26 en la bitácora).
5. Seguir las skills del repo en `.cursor/skills/` (arquitectura, código limpio, UI, Supabase Postgres/SQL,
   Supabase Auth/RLS, datos con Supabase, Cloudinary, MCP, DoD).
6. **Idioma: todo el código en español**, el nuevo y el existente: archivos `.dart` (snake_case), carpetas, clases,
   funciones, variables, parámetros, providers, rutas de go_router, comentarios, textos de UI y tablas/columnas SQL
   (snake_case, sin ñ ni tildes en identificadores).
   Solo quedan en inglés: archivos obligatorios de Flutter (`main.dart`, sufijo `_test.dart`, `pubspec.yaml`,
   `analysis_options.yaml`), archivos de plataforma (`android/`, `ios/`, `linux/`, `windows/`, `macos/`, `web/`),
   generados (`lib/firebase_options.dart`, `google-services.json`, `GoogleService-Info.plist`) y las APIs de
   Flutter/Supabase/Firebase/Riverpod/go_router (`build`, `createState`, `dispose`, `main()`, `ref`, `state`…).
   **Commits totalmente en español** (ver regla 2). Las skills ya reflejan esta regla.
7. **Entornos solo con aprobación del PO.** No hay acceso libre a Supabase, Cloudinary, Firebase Console, GitHub,
   Linear ni ClickUp. Antes de cualquier cambio en un entorno (ejecutar SQL o migraciones, cambiar Auth, presets,
   `firebase deploy`, crear tickets, commit/push…) se presenta al PO un **listado de acciones** con el comando exacto
   y se espera su aprobación explícita. Lecturas y verificaciones sí están permitidas. Ver skill `capsoul-mcp`.
8. **Claves fuera del repo.** Supabase URL y anon/publishable key solo por `--dart-define-from-file=env/dev.json`
   (`env/*.json` ignorado; plantilla en `env/dev.json.example`). Nunca `service_role`, `sb_secret_` ni el
   API secret de Cloudinary en el cliente.
9. **Comunicación 100 % en español (PO, 2026-10-12).** Todo lo de Capsoul va en español: comunicación con el PO,
   reportes, commits (tipo incluido, nunca `feat`/`fix`) y comentarios. No se usa inglés.

## 3. Stack y dependencias

- Flutter 3.47.2 / Dart 3.13.2.
- Backend: **Supabase** (proyecto `capsoul`, ref `mslcdvcmfuqopfwojxvt`, us-east-1) para Auth + Postgres + RLS;
  **Cloudinary** (cloud `dee3zdenh`, plan Free) para medios; **Firebase solo FCM** (`capsoul-ebea3`).
- `go_router ^16.2.0`, `supabase_flutter ^2.18.0` (resuelto 2.18.0; gotrue 2.27.2, postgrest 2.9.1),
  `firebase_core ^4.1.0`, `flutter_riverpod ^3.4.3`, `flutter_lints`.
- Dev: `mocktail ^1.0.5`.
- Quitados el 2026-10-02: `firebase_auth`, `cloud_firestore`, `firebase_storage`, `fake_cloud_firestore`.
- Medios (2026-10-03, rama `funcionalidad/capsulas`): `camera ^0.12.1` (camerax 0.7.5+1, avfoundation 0.10.3+1),
  `record ^7.1.1`, `flutter_image_compress ^2.5.1`, `http ^1.6.0`, `path_provider ^2.1.6`, `flutter_localizations`
  (SDK). Se descartó `video_compress` (sin mantenimiento): el video se graba ya comprimido (720p, 2,5 Mbps, audio 64k).
- Recuerdos y medios (2026-10-03): `uuid ^4.6.0`, `video_player ^2.14.1`, `just_audio ^0.10.6`,
  `flutter_cache_manager ^3.4.5` (Baseflow, 2026-09-19; trae sqflite). Se eligió flutter_cache_manager solo, sin
  `cached_network_image`: la app busca primero el archivo por clave y únicamente pide la URL si falta.
- Previstos: firebase_messaging, flutter_local_notifications.
  CI con GitHub Actions (+ Codemagic para iOS).

## 4. Arquitectura actual

Diagrama completo (ARQ-2): `docs/arquitectura.md`.

```
lib/
  main.dart                          # arranque: inicializarFirebase() (FCM, no bloquea) + inicializarSupabase()
  app_capsoul.dart                   # AppCapsoul (MaterialApp.router)
  firebase_options.dart              # generado por flutterfire (capsoul-ebea3), no se edita
  nucleo/
    errores/fallo_app.dart           # FalloApp, mensajeParaUsuario()
    firebase/arranque_firebase.dart  # inicializarFirebase() (solo FCM)
    firebase/servicio_notificaciones_push.dart  # getToken() seguro (Android/iOS)
    supabase/configuracion_supabase.dart # ConfiguracionSupabase (String.fromEnvironment) + validación
    supabase/arranque_supabase.dart  # inicializarSupabase() -> null o mensaje de error
    arranque/app_error_arranque.dart # AppErrorArranque(detalle) si falta configuración o Supabase no inicia
    enrutador/rutas_app.dart         # RutasApp + resolverRedireccionAutenticacion(modoRecuperacion)
    enrutador/enrutador_app.dart     # proveedorEnrutadorApp, StatefulShellRoute (4 ramas) + /crear
    tema/colores_app.dart            # ColoresApp: primario #1B2A4A, acento #3D6B9A
    tema/tema_app.dart               # TemaApp.claro, radios 12-20
    componentes/                     # BotonPrincipal, mostrarAvisoError/Informativo
  funcionalidades/
    autenticacion/{aplicacion,datos,dominio,presentacion}  # RepositorioAutenticacion(+Supabase), ResultadoRegistro
    usuarios/{aplicacion,datos,dominio}                    # RepositorioUsuarios(+Supabase), AccesoTablaUsuarios
    perfil/{aplicacion,presentacion}                       # ControladorPerfil, PantallaPerfil (Instagram + rejilla momentos)
    navegacion/presentacion/contenedor_navegacion.dart     # barra: Inicio | Momentos | + | Mi legado | Yo
    elementos/{aplicacion,datos,dominio,presentacion}      # LimitesMedios, captura foto/video/audio/nota, compresión, firma+subida
    capsulas/{aplicacion,datos,dominio,presentacion}       # crear, mis cápsulas, detalle (candado, cuenta regresiva, apertura)
    inicio/{aplicacion,datos,dominio,presentacion}         # Inicio del mockup con conteos reales (RepositorioResumenInicio)
    recuerdos/{aplicacion,datos,dominio,presentacion}      # banco de recuerdos, URLs firmadas (firmar-medio), reproductores, elegir
    momentos/{aplicacion,datos,dominio,presentacion}       # feed vertical, crear, detalle bento, filtros perfil
    musica/{aplicacion,datos,dominio,presentacion}       # API pública de Deezer, preview 30 s (streaming), enlaces externos
    legado/{aplicacion,datos,dominio,presentacion}       # herencias, wizard, persona de confianza
    retos/{aplicacion,datos,dominio,presentacion}        # retos globales
    crear/                                                 # selector + hoja opciones crear
test/                                # espejo de lib/ (nucleo/, funcionalidades/) + ayudantes/ (falsos, app_prueba)
docs/README.md                       # índice de documentación técnica
docs/arquitectura.md                 # ARQ-2 v2.1 (2026-10-16): legado, retos, preview música
docs/11-legado-y-retos.md            # suplemento ER legado + retos
docs/migraciones.md                  # catálogo 000001–000016
docs/01-vision-y-objetivos.md        # producto, metas, DoD
docs/03-estructura-proyecto.md       # mapa de carpetas y capas
docs/04-flujos-criticos.md           # arranque, auth, medios, cápsulas, momentos
docs/05-casos-de-uso.md              # actor → pantalla → repositorio
docs/06-integraciones.md             # Supabase, Cloudinary, FCM, secretos
docs/07-patrones-y-convenciones.md   # Riverpod, go_router, nomenclatura
docs/modelo_er.{md,mmd,png}          # modelo ER del director, v1.3 con las correcciones aprobadas por el PO
supabase/migrations/                 # 20261002000001_capsoul_modelo_inicial.sql, 20261002000002_capsoul_programar_trabajos.sql
supabase/migrations/20261003000003_capsoul_limites_medios.sql  # límites, 10 elementos, cuota 200 MB (aplicada)
supabase/migrations/20261004000004_capsoul_recuerdos_momentos.sql # políticas *_leer, títulos, portada (aplicada)
supabase/functions/firmar-subida/       # Edge Function Deno, desplegada (v1, verify_jwt)
supabase/functions/firmar-medio/        # Edge Function Deno: URLs firmadas según RLS, desplegada (v1, verify_jwt)
supabase/pruebas/pruebas_recuerdos_momentos.sql  # pruebas de la 000004 (psql, Postgres local)
.vscode/launch.json                  # perfil "Capsoul (dev)" con --dart-define-from-file=env/dev.json
supabase/pruebas/pruebas_rls_capsoul.sql  # pruebas manuales de RLS (psql)
supabase/pruebas/pruebas_limites_medios.sql  # pruebas de la 000003 (psql, Postgres local)
env/dev.json.example + env/README.md # plantilla de --dart-define-from-file
.cursor/skills/                      # skills del proyecto (capsoul-*)
```

- Rutas: `/inicio`, `/momentos`, `/legado`, `/yo`, `/crear` (+ `/crear/capsula|video|audio|escribir|foto`),
  `/capsulas` (+ `/capsulas/:id`), `/recuerdos` (+ `/recuerdos/nuevo`, `/recuerdos/:id`, elegir recuerdos),
  `/momentos/nuevo`, `/momentos/:id`,
  `/iniciar-sesion`, `/registro`, `/recuperar`, `/revisa-tu-correo?correo=…[&reenviar=1]`, `/nueva-contrasena`.
  Sin sesión solo rutas de autenticación; con sesión, el contenedor; en modo recuperación, solo `/nueva-contrasena`.
- El botón `+` no es una pestaña: hace push de `/crear` (Video, Audio, Escribir, Foto).
- Auth: Supabase Auth email/contraseña con **confirmación de correo obligatoria** (R3). Registro con
  `signUp(data: {'nombre_visible': ...}, emailRedirectTo: 'capsoul://auth/confirmar')`; sin sesión hasta confirmar:
  pantalla "Revisa tu correo" (reenviar con `resend(OtpType.signup)` + enfriamiento de 60 s, volver a iniciar sesión).
  Login con `email_not_confirmed` → aviso en español + "Reenviar correo de confirmación". Recuperar con
  `resetPasswordForEmail(redirectTo: 'capsoul://auth/recuperar')`; el evento `passwordRecovery` activa
  `proveedorModoRecuperacion` → `/nueva-contrasena` (`updateUser(password)`). Deep links con esquema `capsoul`, host
  `auth` (supabase_flutter + app_links; flujo PKCE: el enlace debe abrirse en el mismo dispositivo). Sin aviso de
  verificación en Yo: toda sesión tiene el correo confirmado.
- Tabla `usuarios` (migración oficial): `id` (FK `auth.users`), `nombre_visible` (1..60), `correo`, `foto_public_id`
  (Cloudinary), `perfil_publico`, `ultima_actividad_en`, `creado_en`, `actualizado_en`. La crea el trigger
  `auth_usuarios_1_crear_perfil` desde `raw_user_meta_data->>'nombre_visible'` (o la parte local del correo).
  RLS: solo leo mi propia fila (con correo); amigos y perfiles públicos se leen **sin correo** por la vista
  `public.perfiles_visibles`. Solo edito mi fila y solo `nombre_visible`, `foto_public_id`, `perfil_publico` (GRANT
  por columna). El trigger `auth_usuarios_3_sincronizar_correo` copia cambios de `auth.users.email` y vincula las
  invitaciones al correo nuevo (`privado.vincular_invitaciones_correo`, misma lógica que al confirmar). La app lee/edita
  solo `nombre_visible` de la fila propia.
- Medios (D2): `elementos.cloudinary_tipo_entrega` solo `'authenticated'`, sin `url_segura`, `public_id` aleatorio de
  la Edge Function `firmar-subida`; miniaturas *eager*; URLs firmadas por `firmar-medio` (`private_download_url` con
  `expires_at`: original 24 h, miniatura 7 días); el autor ve sus propios medios antes de `fecha_apertura`.
- Caché de medios en la app: `CargadorMedios` busca el archivo en el dispositivo (`ArchivosMedioDispositivo`,
  flutter_cache_manager `capsoul_medios`, 400 objetos, 60 días sin uso) con clave `public_id|miniatura` o
  `public_id|original`; si falta, pide el enlace a `RepositorioUrlsMedioAgrupado`, que reutiliza los vigentes de
  `CacheEnlacesMedio` (memoria, por `public_id` y variante, margen de 5 min) y agrupa los que faltan en una llamada.
  Listas, rejillas, bento y selección usan solo la miniatura; el original solo en el detalle (foto, video, audio).
  Al cerrar sesión o cambiar de cuenta se vacían ambas cachés.
- Migración `20261002000001` v1.3 **aplicada** el 2026-10-03 en el proyecto `capsoul` (Management API, registrada en
  `supabase_migrations.schema_migrations`). Auth configurado: *Site URL* `capsoul://auth/confirmar`, redirecciones
  `capsoul://auth/confirmar` y `capsoul://auth/recuperar`, confirmación de correo obligatoria, SMTP Resend.
- `firestore.rules` y `firebase.json` siguen en el repo pero ya no se usan (borrado propuesto al PO).
- UI en español.

## 5. Estado por sprint

| Sprint | Objetivo | Estado |
|---|---|---|
| S1 | Cimientos: estructura, tema, navegación, init Firebase, org, skills | ✅ Terminado (en `develop`, validación de Capsoul en ClickUp y Linear) |
| S2 | Identidad y autenticación (registro, inicio de sesión, recuperar, sesión, perfil, reglas) | ✅ **Cerrado** (2026-10-03) en `develop`: Supabase Auth + R3 confirmación de correo obligatoria + deep links; migración 000001 aplicada, Auth configurado y el PO probó registro e inicio de sesión con correo OK |
| MIG | Migración a Supabase + Cloudinary (Firebase solo FCM) | 🟡 Modelo 1.3 aplicado y Auth en Supabase; pendiente 000002 (pg_cron), Edge Functions y Cloudinary firmado |
| S4 | Ruta crítica de cápsulas + Security Rules | 🟡 En rama local `funcionalidad/capsulas` (sin push): elementos base, crear/detalle de cápsula, Inicio, banco de recuerdos, momentos (bento), reproductores; migraciones 000003 y 000004 aplicadas; `firmar-subida` y `firmar-medio` desplegadas; falta revisión del PO y push |
| S8 | Endurecer reglas + FCM | ⏳ |
| IMG | Icono de app + imagenes locales de capsula | En rama local `funcionalidad/imagenes-capsula` (sin commit): migracion 000020 aplicada en remoto; PR hacia `develop` pendiente de revision |

## 6. Pendientes abiertos

Todo lo que toca un entorno requiere aprobación del PO (regla 7).

- [x] (2026-10-30, aplicada en remoto con aprobacion del PO y registrada en `schema_migrations`) `20261030000020_capsoul_imagen_capsula.sql` (columna `capsulas.imagen_clave` + check, grant update, recrear
      `capsulas_recibidas()` con `imagen_clave`). Sin ella la app falla al listar/crear capsulas. Numero 000019 reservado por el PR #9.
- [ ] PO: revisar la rama `funcionalidad/imagenes-capsula` (icono, selector en crear/editar, tarjetas) y autorizar commit.
- [ ] PO: la 000002 está registrada en `schema_migrations`, pero en remoto solo existen los jobs `capsoul-liberar-capsulas`
      y `capsoul-activar-herencias` (verificado el 2026-10-12). Falta `capsoul-enviar-avisos` y Vault está vacío
      (`project_url`, `llave_cron`).
- [ ] PO: los objetos de **000007–000010** ya existen en remoto (tabla `pendientes_borrado_medio`, `invitaciones_amistad`,
      `usuarios.nombre_usuario`, GRANT por columnas de `capsulas`), pero **no están registrados** en
      `supabase_migrations.schema_migrations` (solo 000001–000006). Comparar con los archivos y registrarlas, sin reaplicar.
- [ ] Director: actualizar RF-05 en Drive si hace falta (no existe en el repo; la copia 02 v1.2 ya pide confirmación
      obligatoria y la pantalla "Revisa tu correo").
- [ ] Llamar `registrar_actividad()` (RPC) al abrir la app, para herencias por inactividad.
- [ ] PO: revisar la rama `funcionalidad/capsulas` y autorizar push / PR a `develop`.
- [ ] Huérfanos en Cloudinary: la 000008 crea la cola `privado.pendientes_borrado_medio` (trigger `after delete` en
      `elementos`), pero **falta el procesador** (Edge Function protegida o job, idempotente, por lotes, Admin API de
      Cloudinary con secretos en `Deno.env`) y cubrir subidas sin fila en `elementos`. Los 4 huérfanos del 2026-10-03 ya se borraron.
- [ ] Probar con un medio real la miniatura por Download API + `transformation` (foto y, sobre todo, video `so_0`):
      se verificó con un recurso `upload` de ejemplo (480 px) y la firma contra recursos inexistentes, no con un
      derivado eager `authenticated`. La Download API no pasa por la CDN (Cloudinary cobra el doble de ancho de
      banda): la caché del dispositivo lo compensa.
- [ ] Video y audio se descargan completos antes de reproducir (≤ 20 MB / ≤ 3 MB); valorar streaming + caché.
- [ ] iOS: AVPlayer con la URL de la Download API depende del Content-Type; probar video/audio en iPhone.
- [ ] Momentos: visibilidad siempre `privado` (el enum admite cercanos/amigos); falta UI para compartir.
- [ ] Un plugin avisa en el build Android sobre "Built-in Kotlin"; revisar al actualizar dependencias.
- [ ] El tamaño declarado no lo puede imponer la firma de Cloudinary: valorar verificación posterior (webhook
      `notification_url` o revisión en `firmar-medio`).
- [ ] `miniatura_public_id` queda en null (eager crea la miniatura derivada; falta guardarla/servirla).
- [ ] `pruebas_rls_capsoul.sql` inserta una foto sin `bytes`: con la 000003 esa línea fallará por el check (esperado).
- [ ] iOS: verificar en Mac la compilación con camera/record (deployment target) y los permisos.
- [ ] Borrar `firestore.rules` y `firebase.json` y desactivar Firebase Auth/Firestore/Storage en la consola (decisión del PO).
- [ ] Edge Function `enviar-avisos` (DEV-100): **fuera de los commits** y sin desplegar. Antes hay que validar la cabecera del
      cron contra un secreto (hoy `verify_jwt = false` sin comprobación), migrar de FCM legacy (`fcm/send`) a HTTP v1 con
      cuenta de servicio, no devolver errores internos y reclamar filas de forma atómica.
- [ ] PO: probar en dispositivo lo que falta del flujo (login sin confirmar → reenviar; recuperar → enlace → nueva
      contraseña; editar nombre, cerrar sesión, sesión persistente). Registro e inicio de sesión con correo: OK.
- [ ] Vigilar el límite de Resend (plan gratuito, 100 correos/día) y el rate limit de correos de Supabase Auth.
- [ ] iOS: falta `ios/Runner/GoogleService-Info.plist` (necesario para FCM).
- [ ] Actualizar remoto local: `git remote set-url origin https://github.com/DeibyRamirez/Capsoul.git`.
- [ ] S1-07: instalar packs oficiales de skills (ver `.cursor/skills/README.md`).
- [ ] FCM (`firebase_messaging`) · CI.
- [ ] Revisar si se abre PR `develop` → `main`.
- [ ] UI para **editar momentos y recuerdos** (los repositorios ya tienen `actualizarMetadatos`; falta pantalla).
- [ ] `infra/scripts/sincronizar_migraciones.ps1` solo copia los archivos: no añade marcadores `-- migrate:up/down` y
      sobrescribiría las copias de 000006 y 000010 que ya los tienen. Las copias de 000007–000009 siguen sin marcadores dbmate.
- [ ] PO: aplicar `20261030000023_capsoul_musica_deezer.sql` (no aplicada). Sin ella, guardar un recuerdo de música de Deezer
      falla con 23514 (`elementos_musica_proveedor_valido` solo admitía `spotify`). Aplicarla antes de publicar la rama.
- [ ] PO: revisar la rama local `funcionalidad/musica-deezer` (worktree `..\capsould-musica`, sin commit) y autorizar commits.
- [ ] Música/Deezer: los términos de la API son de uso **no comercial** y piden avisar de que el streaming es de uso
      personal (la app muestra «Vistas previas de 30 s, solo para uso personal»). Si Capsoul se monetiza hace falta un
      acuerdo con Deezer. El crédito usa el icono de Deezer de Font Awesome; valorar el logo oficial del brand kit.
- [ ] La Edge Function `buscar-musica` (Spotify + respaldo Deezer) ya no la usa la app: decidir si se retira y se
      borran los secretos `SPOTIFY_*` (requiere aprobación del PO).
- [ ] Probar en dispositivo el preview de Deezer (Android e iOS) y «Abrir en Deezer» con y sin la app instalada.

## 7. Decisiones (ADR corto)

- **2026-09-25** Flutter (una base de código para Android e iOS) + Firebase serverless (ARQ-1, Linear DEV-89).
- **2026-09-25** go_router con `StatefulShellRoute` para conservar el estado de cada pestaña.
- **2026-09-25** Firebase se inicializa de forma diferida para que la app corra sin `firebase_options.dart`.
- **2026-09-26** Renombre de Capsould a Capsoul (org `com.capsoul`, paquete `capsoul`).
- **2026-09-26** Commits en español, incluido el tipo.
- **2026-09-26** Todo el código en español (regla 6). Estructura: `lib/nucleo/` (compartido: errores, firebase,
  enrutador, tema, componentes) y `lib/funcionalidades/<funcionalidad>/` con capas `presentacion/`, `aplicacion/`,
  `dominio/`, `datos/`. `test/` replica la estructura; `test/ayudantes/` para falsos. Clase raíz `AppCapsoul`.
- **2026-09-26** Campos de Firestore en español: colección `usuarios/{uid}` con `nombreVisible`, `correo`, `fotoUrl`,
  `creadoEn`. Los códigos de error de Firebase (`invalid-credential`, …) se conservan tal cual porque son de la API.
- **2026-10-02** **Migración de backend:** Supabase (Postgres + Auth + RLS) reemplaza a Firebase Auth/Firestore y
  Cloudinary reemplaza a Firebase Storage. Firebase queda **solo para FCM** (`firebase_core`, `firebase_options.dart`,
  `google-services.json`). Reemplaza las decisiones de Firestore del 2026-09-26.
- **2026-10-02** Modelo ER y SQL oficiales los entrega el director (copiados byte a byte, SHA-256 verificado); no se
  modifican en el repo, los problemas se reportan como propuesta.
- **2026-10-02** El perfil `usuarios` lo crea un trigger del servidor (no el cliente). El perfil se lee bajo demanda y
  se vuelve a leer tras editarlo (sin Realtime). Los códigos de error son los `error_code` de Supabase Auth
  (`invalid_credentials`, `email_not_confirmed`, …) y los SQLSTATE de Postgres (`42501`, `23514`).
- **2026-10-02** Configuración por `--dart-define-from-file`; si falta, `AppErrorArranque` explica qué variable falta.
- **2026-10-03** R3: confirmación de correo **obligatoria**; deep links fijos `capsoul://auth/confirmar` y
  `capsoul://auth/recuperar` (constantes en `ConfiguracionSupabase`, ya no `SUPABASE_URL_REDIRECCION`).
- **2026-10-03** PO: Supabase plan Free; SMTP con Resend (plan gratuito, 100 correos/día), remitente
  `no-responder@send.cheiviz.com`; `private_download_url` de Cloudinary con `expires_at` de 1 h; el autor ve sus
  propios medios antes de `fecha_apertura`.
- **2026-10-03** SQL 1.3: permisos por defecto globales del rol postgres (`alter default privileges for role postgres
  revoke execute on functions from public`; la variante `in schema` no quita el EXECUTE de PUBLIC) y vinculación de
  invitaciones también al cambiar el correo (solo cuentas con `email_confirmed_at`).
- **2026-10-03** Límites de medios aprobados por el PO, centralizados en `LimitesMedios` (MB binarios): foto lado
  mayor ≤ 1600 px, JPEG 75, ≤ 2 MB; video 720p ≤ 60 s ~2,5 Mbps ≤ 20 MB; audio AAC mono 64 kbps ≤ 5 min (tope 3 MB);
  nota ≤ 5000 caracteres; ≤ 10 elementos por cápsula; cuota 200 MB por usuario validada en servidor (trigger CAP01,
  máximo de elementos CAP02, checks 23514). Compresión en el teléfono antes de subir.
- **2026-10-03** Guardado de cápsula: subir medios → insertar `elementos` → cápsula en `borrador` → `capsula_elementos`
  → `programada`; si falla, se borran cápsula y elementos. `public_id` `capsoul/<uuid>` (sin uid), `type=authenticated`,
  eager de miniatura (video con `eager_async`), `allowed_formats` firmado.
- **2026-10-03** Fecha de apertura: solo días futuros (desde mañana); desde 2026-10-12 también **hora** elegible en crear/editar cápsula (hora local). Material en español
  (`flutter_localizations`, `es_CO`).
- **2026-10-03** Inserts con id generado en el cliente (`uuid`) y **sin RETURNING**: el error al guardar venía de
  que RETURNING exige política SELECT; la 000004 añade las políticas `*_leer` (elementos, momentos, enlaces).
- **2026-10-03** `firmar-medio`: firma solo lo que RLS deja leer al usuario; original con `private_download_url`
  (1 h), miniatura con URL de entrega firmada (`c_limit,q_auto,w_480`; video `c_limit,q_auto,so_0,w_480`).
  **Reemplazado** el mismo día (v2, abajo).
- **2026-10-03** PO: **se mantiene la barra inferior actual** ("Inicio | Momentos | + | Mi legado | Yo", la de la
  skill UI) en lugar de la del mockup.
- **2026-10-03** PO: `firmar-medio` v2: original a **24 h** y miniatura a **7 días**, ambas con `private_download_url`
  firmada (la miniatura con `transformation` del derivado eager y formato jpg) y caducidad propia
  (`expira_original`, `expira_miniatura`; `expira_en` = original por compatibilidad; `public_id` en la respuesta).
  En la app, **caché por `public_id`** (no por URL) para ahorrar ancho de banda de Cloudinary: archivos en el
  dispositivo y enlaces vigentes en memoria reutilizados hasta 5 min antes de caducar.
- **2026-10-03** Banco de recuerdos: los elementos se guardan sueltos y se eligen al crear cápsulas o momentos; el
  "+" guarda el recuerdo y lleva a `/recuerdos`. Crear cápsula = borrador → enlaces → programada (si falla, se borra
  solo la cápsula; 23503 → recuerdo que ya no existe).
- **2026-10-03** Momentos: título 1..80, descripción ≤ 500, 1..60 recuerdos, portada foto/video del propio momento
  (CAP04 en servidor); rejilla bento de 4 columnas calculada en `distribuirBento` (función pura).
- **2026-09-26** Riverpod como gestor de estado único; repositorios detrás de interfaces abstractas inyectadas por
  proveedores (`proveedorRepositorioAutenticacion`, `proveedorRepositorioUsuarios`) para simularlos en pruebas.

## 8. Bitácora

- **2026-09-25** S1: estructura, tema, router, pantallas base y bootstrap de Firebase. Org `com.example.capsould` → `com.capsould`.
- **2026-09-26** Renombre a Capsoul. Push de S1 a `develop` (9 commits, f375fb4…43984f5).
- **2026-09-26** Incidente: el commit `43984f5` corrompió caracteres en Info.plist, my_application.cc,
  main.cpp y README (script de reemplazo defectuoso). Capsoul lo detectó (FAIL). Corregido en `11e6977`.
  PO verificó la app en debug.
- **2026-09-26** Skills del proyecto exportadas a `.cursor/skills/` (`1079f8c`). S1 cerrado en `develop`.
- **2026-09-26** Se crea este `Memory.md`.
- **2026-09-26** Cierre de Firebase (`firebase_options.dart`, `google-services.json`, `firebase.json`, Gradle) en el
  working tree, sin commit.
- **2026-09-26** Migración al español de todo `lib/` y `test/` (S1 + S2): 47 archivos renombrados con `git mv` uno por uno
  y reescritos a mano, rutas en español, `users` → `usuarios`. Sin cambios en archivos de plataforma (verificado por hash).
- **2026-09-26** S2 Identidad y autenticación: registro (nombre visible, correo, contraseña ≥ 8 y confirmación) que crea
  `usuarios/{uid}` y envía verificación sin bloquear; inicio de sesión con carga/errores en español; recuperar contraseña
  con confirmación neutra; redirección por `authStateChanges`; pestaña Yo con perfil, editar nombre, reenviar
  verificación y cerrar sesión; `firestore.rules` de dueño. `flutter analyze` 0 issues, 57 tests verdes,
  `flutter build apk --debug` OK. Pendiente commit y prueba del PO.
- **2026-09-26** ARQ-2: `docs/arquitectura.md` con diagramas Mermaid de arquitectura/infraestructura y de liberación de
  cápsulas.
- **2026-09-27** Con autorización del PO se crearon los 5 commits (compilación(firebase), refactorización(idioma),
  seguridad(reglas), documentación(arquitectura), documentación(memoria)) y se subieron a `develop`.
- **2026-10-02** Decisión del PO: migrar a Supabase + Cloudinary (Firebase solo FCM) y regla nueva de pedir aprobación
  antes de tocar entornos (regla 7).
- **2026-10-02** Skills: nuevas `capsoul-supabase-postgres-sql`, `capsoul-cloudinary-medios`, `capsoul-mcp`;
  `capsoul-firebase-integrity` → `capsoul-supabase-auth-rls` y `capsoul-firestore-storage` → `capsoul-supabase-datos`
  (con `git mv`); actualizadas arquitectura, código limpio, UI, DoD y README (identificadores en español).
- **2026-10-02** Copiados los archivos oficiales del director: `docs/modelo_er.{md,mmd,png}`,
  `supabase/migrations/20261002000001_capsoul_modelo_inicial.sql`, `…000002_capsoul_programar_trabajos.sql`,
  `supabase/pruebas/pruebas_rls_capsoul.sql`. Sintaxis revisada con el parser de Postgres (pglast) sin ejecutar nada.
- **2026-10-02** Auth con Supabase: `RepositorioAutenticacionSupabase`, `RepositorioUsuariosSupabase` (+
  `AccesoTablaUsuarios`), `inicializarSupabase()`, `env/dev.json.example`, `env/*.json` en `.gitignore`. Quitados
  firebase_auth, cloud_firestore, firebase_storage y fake_cloud_firestore. Solo cambiaron registrantes de plugins
  generados (linux/macos/windows); nada en android/ios/web. `flutter analyze` 0 issues, 76 tests verdes,
  `flutter build apk --debug` OK. Sin commit; nada ejecutado en Supabase, Cloudinary ni Firebase.
- **2026-10-02** Correcciones del SQL aprobadas por el PO (migración v1.2): correo privado (política `usuarios_leer` solo
  fila propia + vista `perfiles_visibles` con función definer), trigger `auth_usuarios_3_sincronizar_correo`, revocación
  final de EXECUTE en `privado` con grants mínimos a lo que usan las políticas, delta D2 del director (solo
  `authenticated`, sin `url_segura`, `public_id` aleatorio, miniaturas *eager*) y requisitos en la cabecera de la
  migración 000002. Verificado en un Postgres 17 local desechable en el box (migración + `pruebas_rls_capsoul.sql` con
  pruebas nuevas de correo privado). `docs/modelo_er.*` actualizado (PNG regenerado) y `docs/arquitectura.md` reescrito.
- **2026-10-02** Con autorización del PO se crearon 4 commits **locales** en `develop` (skills, modelo, auth, memoria),
  **sin push**.
- **2026-10-03** R3 confirmación de correo obligatoria: pantalla `/revisa-tu-correo` (correo, reenviar con
  enfriamiento de 60 s, carga y mensajes en español, volver a iniciar sesión); login con `email_not_confirmed` ofrece
  reenviar; quitado el aviso de verificación de Yo; `emailRedirectTo`/`redirectTo` con `capsoul://auth/confirmar` y
  `capsoul://auth/recuperar`; pantalla mínima `/nueva-contrasena` para el evento `passwordRecovery`. Deep link en
  `AndroidManifest.xml` e `Info.plist` editados a mano y **sin commit** (revisión del PO). `env/README.md` y
  `env/dev.json.example` sin `SUPABASE_URL_REDIRECCION`. `flutter analyze` 0 issues, 93 tests verdes,
  `flutter build apk --debug` OK.
- **2026-10-03** SQL 1.3 (permisos por defecto globales + `privado.vincular_invitaciones_correo` usada por los triggers
  2 y 3) con pruebas RLS nuevas; pglast OK y verificado en un Postgres 17 desechable en el box (borrado después).
  `docs/modelo_er.md` → 1.3 (D5 cerrado, supuesto 12 confirmado).
- **2026-10-03** Entorno ya hecho por el PO: Resend configurado como SMTP de Supabase (plan gratuito, 100 correos/día).
  Con su autorización se crearon 3 commits **locales** (auth, modelo, memoria), **sin push**; nada ejecutado en
  Supabase, Cloudinary ni Firebase.
- **2026-10-03** Cierre de S2. Entorno hecho por el PO: migración 000001 v1.3 aplicada (Management API, registrada en
  `supabase_migrations.schema_migrations`); Auth con *Site URL* `capsoul://auth/confirmar`, redirecciones confirmar/recuperar,
  confirmación obligatoria y SMTP Resend. El PO probó registro e inicio de sesión con correo: OK. Commits
  `configuración(plataforma)` (deep links), `documentación(migraciones)` y `documentación(memoria)`; push a `origin/develop`
  autorizado por el PO.
- **2026-10-03** S4 en rama local `funcionalidad/capsulas` (desde `develop` 48e14c9, **sin push**): elementos base (foto y
  video con cámara frontal/trasera, video ≤ 60 s con contador, nota de voz con onda ≤ 5 min, nota ≤ 5000), compresión y
  límites (`LimitesMedios`), crear cápsula (varios elementos con vista previa, título, mensaje, fecha futura,
  destinatario "Próximamente"), mis cápsulas, detalle del mockup (candado, cuenta regresiva, el autor ve el contenido,
  animación de frasco que se ilumina y abre), Inicio del mockup con conteos reales. Permisos de cámara/micrófono a mano
  en AndroidManifest e Info.plist. Backend como archivos: migración 000003 (probada en Postgres 17 desechable en el box:
  checks, CAP01, CAP02, permisos) y Edge Function `firmar-subida` (`deno check`, `deno lint`, 5 pruebas `deno test`,
  firma verificada con el ejemplo oficial de Cloudinary). `flutter analyze` 0 issues, 159 tests verdes,
  `flutter build apk --debug` OK. Nada desplegado ni ejecutado en Supabase, Cloudinary ni Firebase.
- **2026-10-03** Plan B aprobado por el PO (rama local `funcionalidad/capsulas`, sin push). (1) Arreglo del error al
  guardar: ids generados en el cliente sin RETURNING y migración 000004 (políticas `*_leer`, `elementos.titulo` y
  `fecha_recuerdo`, `momentos.titulo` y `portada_elemento_id`) aplicada por Management API y registrada en
  `schema_migrations`; verificada con inserts dentro de una transacción con ROLLBACK y 22 pruebas SQL en Postgres
  desechable. (2) Banco de recuerdos (`/recuerdos`): filtros, guardar, detalle, borrar. (3) Crear cápsula eligiendo
  recuerdos o capturando uno nuevo. (4) Momentos: crear con filtros rápidos o a mano, portada, listado y detalle bento.
  (5) `firmar-medio` desplegada (401 sin JWT o con JWT inválido; firmas validadas contra `cloudinary@2.11.0`) y
  reproductores `video_player` ^2.14.1 / `just_audio` ^0.10.6; `uuid` ^4.6.0; permiso INTERNET en el
  AndroidManifest principal (a mano). (6) Borrados en Cloudinary (autorizado) los 4 huérfanos de inserts fallidos;
  `.vscode/launch.json` con "Capsoul (dev)".
- **2026-10-03** Caché de medios (aprobado por el PO): `firmar-medio` v2 desplegada (miniatura 7 d, original 24 h,
  ambas temporales y firmadas; 401 sin JWT, con JWT inválido y con firma alterada). En la app,
  flutter_cache_manager 3.4.5 con clave `public_id|variante`, `CacheEnlacesMedio` con margen de 5 min y
  `CargadorMedios` que evita descargas repetidas; listas y rejillas solo con miniatura. Se corrigió
  `docs/modelo_er.md` (000001, 000003 y 000004 aplicadas) y `docs/arquitectura.md`.
- **2026-10-03** FCM, documentación, Perfil y Momentos: `getToken()` movido a
  `nucleo/firebase/servicio_notificaciones_push.dart` (solo Android/iOS, try/catch, no bloquea arranque).
  Documentación ampliada en `docs/` (README, visión, estructura, flujos, casos de uso, integraciones, patrones).
- **2026-10-03** Intercambio Perfil ↔ Momentos: Perfil = cabecera Instagram + grid 3 col de recuerdos
  (`rejilla_elementos_perfil.dart`); Momentos = búsqueda + chips + grid 2 col `TarjetaMomento`
  (`rejilla_momentos.dart`). Eliminados `rejilla_momentos_perfil` y `tarjeta_momento_feed`.
  `flutter analyze` 0 issues, tests verdes. Sin commit.
- **2026-10-12** Regla 9: todo en español (comunicación, reportes, commits y comentarios), por instrucción del PO. Se creó `.env` (solo CLI) con `SUPABASE_ACCESS_TOKEN` vacío y se agregó `.env` a `.gitignore`, sin commit.
- **2026-10-12** Plan maestro `todo.md` (implementación local, **sin commit/push/deploy** salvo autorización PO): baseline analyze 0; DEV-97 sesión en `flutter_secure_storage`; CRUD cápsulas/recuerdos/momentos en repos; migraciones **000007** (GRANT columnas) y **000008** (cola `pendientes_borrado_medio`); prueba SQL `pruebas_liberar_capsulas.sql`; Edge **`enviar-avisos`** + `config.toml`; FCM → `dispositivos_push` (`EscuchaTokensPush`, borrado al cerrar sesión); UI destinatario (`/capsulas/recibidas`, `marcar_abierta`); editar/cancelar/eliminar cápsula; CI `.github/workflows/ci.yml`; docs VPS y CHECK música. **Remoto pendiente PO:** aplicar migraciones 000002/000007/000008, desplegar `enviar-avisos`, Vault/cron, secretos FCM/Resend. `flutter test` 230 OK.
- **2026-10-12** Plan compartir cápsulas y amigos (friends_only): migración **000009** (`invitaciones_amistad`, `mis_amigos`, destinatario por `usuario_id` + RLS amistad); feature `amistades/` y selector de amigo en crear cápsula; deep links fase 1 (`EscuchaEnlacesApp`, `capsoul://capsula` / `capsoul://amistad`); docs `04-flujos-criticos` §4.2–4.3, `05-casos-de-uso`, `enlaces-app-fase2.md`. **PO:** aplicar 000009 y cron 000002 (`docs/migraciones.md`, `infra/scripts/aplicar_cron_parcial_capsoul.sql`).
- **2026-10-12** Amistades por **@** (sustituto principal del enlace de invitación): migración **000010** (`nombre_usuario`, `resolver_usuario_por_arroba`, `enviar_solicitud_amistad`, `establecer_mi_nombre_usuario`); registro + `/elegir-usuario`; búsqueda exacta en `pantalla_amigos`; filtro @ en crear cápsula. Deep links `capsoul://auth/*` se mantienen; `capsoul://amistad` solo compatibilidad. **PO:** aplicar 000010 en remoto.
- **2026-10-12** Restyle UI al sistema de diseño claro (`docs/design_system_for_flutter.md`, aprobado por el PO): tokens nuevos en `ColoresApp` (primario #1B316B, degradado #E2EDF8→#F4F8FC, borde #D6E4F0, texto #111E38/#5A6E94, nav #8FA1C2, dorado, medianoche #132247), `TemaApp` con Poppins/Playfair (assets OFL en `assets/fonts`), botones píldora 48, tarjetas con borde y sombra; luciérnagas (`CieloNocturno`, sin tocar) dentro de tarjetas medianoche en Inicio, auth y detalle de cápsula; `docs/Design.md` actualizado. Sin commit.
- **2026-10-12** Cierre verificación auth/medios/cápsulas: destinatarios **múltiples** (checkbox) en crear; **editar** cápsula con recuerdos, destinatarios y metadatos (`actualizarCapsulaEditable`, lectura `capsula_destinatarios`); selector de **fecha y hora**; componentes `selector_destinatarios_amigos.dart` y `elegir_fecha_hora_apertura.dart`. Pruebas en `capsulas/` ampliadas. **PO (dispositivo):** flujo crear → editar → destinatario en «Para mí»; subida real con `firmar-subida`.
- **2026-10-12** Auditoría previa al push y correcciones aprobadas por el PO: `flutter analyze` **0 issues** y `flutter test`
  **245** en verde. La creación queda centralizada en el selector «Crear» (se quitaron los FAB comentados de Mis cápsulas,
  Momentos y Recuerdos y el `_nuevo` sin uso); las pruebas de Inicio y Recuerdos se adaptaron a ese flujo. Inicializadores
  privados en repositorios de amistades y cápsulas, `@override` en `RepositorioDispositivosPush`, imports sin uso.
  Estado remoto verificado (solo lectura): 000001–000006 registradas; objetos de 000007–000010 presentes sin registrar;
  funciones `firmar-subida` v2, `firmar-medio` v3, `buscar-musica` v7 (todas con JWT); cron con 2 jobs; Vault vacío.
  `enviar-avisos` queda fuera de los commits (pendiente de seguridad y FCM v1). Commits locales en `develop`, **sin push**.
- **2026-10-16** Avatares de perfil: `AvatarPerfil`/`proveedorUrlAvatarPerfil` enlazados a `foto_public_id`, firma batch `avatares_usuario_ids` en `firmar-medio`, RPC `mis_amigos` + solicitudes con foto, UI `AvatarUsuario` en Yo y Amigos. **PO:** migración `20261016000013` y redeploy `firmar-medio`.
- **2026-10-16** Avatar visible en Yo: `transformaciones_medios.ts` alinea eager de `firmar-subida` y miniatura de `firmar-medio` (`c_limit,w_480,q_auto`); Flutter prioriza URL original, `ImagenAvatarRed` con respaldo, refresh en Yo invalida perfil + firma; aviso si falla `firmar-medio`. **PO:** redeploy `firmar-medio` y `firmar-subida`; re-subir foto si el eager anterior no coincidía.
- **2026-10-16** Módulo Mi legado: migración `20261016000014` (confianza global @, `herencia_capsulas`, metadatos, eventos, RPC), feature `legado/` (UI mock, wizard 6 pasos, `RepositorioLegado` Supabase + stub HTTP), contratos `docs/contrato-legado.json` y `contrato-api-legado.md`. **PO:** aplicar migración en remoto.
- **2026-10-16** Avatar cargando infinito: `ref.read` en providers de avatar, timeout 45 s en `invoke` de `firmar-medio`, logs debug, `ImagenAvatarRed` con `loadingBuilder` y timeout de descarga; `mensajeParaUsuario` entiende `ErrorFuncionesApi`; guía `docs/verificacion-avatar-perfil.md`. **PO:** ejecutar checklist (foto_public_id + deploy Edge).
- **2026-10-16** `EncabezadoSeccionCapsoul` y `PildorasSeleccionCapsoul` en núcleo; cabecera unificada en Momentos, Recuerdos, Retos y Legado. Listado Mis cápsulas con tarjetas mockup y pestañas Mis cápsulas / Para mí (`pantalla_capsulas_recibidas` reutiliza la misma pantalla).
- **2026-10-16** UI pantalla Retos alineada al mockup (pestañas Activos/Completados/Favoritos, secciones diario/semanal/especial);
  clasificación en cliente (`clasificacion_retos_ui.dart`) hasta migración de categorías/favoritos en backend.
- **2026-10-16** Importar recuerdos desde el dispositivo: hoja «Capturar» vs galería/archivos (`ImportadorMediosDispositivo`,
  `image_picker`, `file_picker`), integrado en `capturarRecuerdo` y acción en pantallas de captura. Permisos Android
  `READ_MEDIA_*` + `READ_EXTERNAL_STORAGE` (≤ API 32); iOS `NSPhotoLibraryUsageDescription`. Documentación
  `docs/10-permisos-dispositivo-y-privacidad.md` y actualización de `04-flujos-criticos` / `06-integraciones`.
- **2026-10-16** Corrección del CI del PR #2 (develop → main): `deno test` de `firmar-medio` con `--allow-env` acotado a `CLOUDINARY_URL`, `CLOUDINARY_ACCOUNT_URL` y `CLOUDINARY_API_PROXY` (el SDK npm de Cloudinary que usa la prueba como referencia las lee al importarse; la lógica de firma ya estaba aislada en `firma_entrega.ts`); `api/**` excluido del análisis raíz y job `api` aparte (`dart pub get` + `dart analyze --fatal-infos`); limpieza de avisos del analizador (imports, `_`, formales de inicialización, elementos null-aware, `RadioGroup` en `pantalla_nueva_herencia`, llaves, `const`); pruebas de Inicio y del botón + actualizadas a la UI actual (hoja de opciones, píldoras, etiquetas con relleno). Deno 2.9.7 instalado en el PC del PO. `flutter analyze` 0, `flutter test` 306 OK, Deno 17 OK.
- **2026-10-26** DEV-95 / DEV-99: el feed de cápsulas tiene tres pestañas (Mis cápsulas, Para mí mismo, Para mí) sin duplicar; la tarjeta lee `estado_capsula` y una fecha vencida sigue «Programada» hasta que el cron libere. Migración nueva `20261026000016` (el autor puede insertarse como destinatario; hay que aplicarla a mano en Supabase). `liberar_capsulas_vencidas()` no tenía bug: las aserciones locales confirman una sola liberación, cero cambios al repetir y una sola fila de aviso en dos sesiones. Job `sql` en CI. `flutter analyze` 0, `flutter test` 318, Deno 17, SQL local en verde. **PO:** aplicar 000016 antes de probar «También para mí» en el teléfono.
- **2026-10-18** CI de compilación (`.github/workflows/build.yml`, se dispara con push a `main` y `workflow_dispatch`): job `android` (ubuntu, Java 17) genera APK y AAB release y los sube como artefactos; job `ios` (macos) compila con `flutter build ios --release --no-codesign` y empaqueta `capsoul-sin-firmar.ipa` (sin firmar: no sirve para TestFlight). `env/dev.json` se crea desde secretos con `jq`, sin imprimirlos; el job falla si la clave empieza por `sbp_`/`sb_secret_`. Secretos de GitHub: **obligatorios** `SUPABASE_URL`, `SUPABASE_ANON_KEY`; opcionales `API_BASE_URL`, `BACKEND`, `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` (sin keystore firma con debug y emite `::warning::`) e `IOS_GOOGLE_SERVICE_INFO_BASE64`. `android/app/build.gradle.kts` lee `android/key.properties` (ignorado) y si no existe usa la firma debug. iOS: `ios/Podfile` con `platform :ios, '15.0'` (mínimo de Firebase iOS SDK 12), `#include?` de Pods en `Debug/Release.xcconfig`, `Info.plist` con `UIBackgroundModes` (`remote-notification`) y `LSApplicationQueriesSchemes` (`spotify`). La primera ejecución será al fusionar el PR develop → main (antes hay que crear los secretos); después, manual con *Run workflow*. Pendiente: capability Push/APNs y firma iOS desde una Mac. `flutter analyze` sin issues; `flutter build apk --release` local OK (66,4 MB, firmado con debug).
- **2026-10-30** Rama `funcionalidad/imagenes-capsula` desde `origin/develop` (sin commit). Icono de app con
  `flutter_launcher_icons` (Android adaptativo, fondo `#1B316B`; iOS sin alfa). 16 imagenes de
  `assets/capsoul_assets/01_capsulas_mejoradas` a WebP q88 en `assets/imagenes_capsula/capsula_NN.webp`
  (4,1 MB a 228 KB). Catalogo `ImagenCapsula` (claves `capsula_01`..`capsula_16`, por defecto `capsula_01`), selector
  en crear y editar capsula, miniatura en las tarjetas de Mis capsulas (reemplaza el frasco). Columna
  `capsulas.imagen_clave` en la migracion 000020 (sin aplicar); el update solo envia claves del catalogo.
  Goldens en `test/capturas/goldens/`. `flutter analyze` 0 issues, 340 tests verdes, `flutter build apk --debug` OK.
  Los originales de `assets/capsoul_assets/` quedan fuera de git.
- **2026-10-30** Música con la API pública de Deezer (rama local `funcionalidad/musica-deezer` desde `origin/develop`,
  worktree `..\capsould-musica`, **sin commit**). La búsqueda deja la Edge Function `buscar-musica` (Spotify) y llama
  directo a `https://api.deezer.com/search` con `RepositorioMusicaDeezer` (http.Client inyectable, timeout 8 s, errores
  de Deezer `{"error":{code}}` → `FalloMusica` en español; 800 → pista inexistente, 4 → cuota). Modelo inmutable
  `PistaDeezer.fromJson`. `ControladorBusquedaMusica` (Riverpod, debounce 400 ms, número de petición para ignorar
  respuestas viejas, estados inicial/cargando/vacío/error con Reintentar). Preview de 30 s solo en **streaming** con
  just_audio (se quitó la descarga a archivo temporal), `CoordinadorPreviewMusica` para que solo suene uno a la vez,
  barra de progreso, se detiene al salir y antes de abrir otra app; estado «sin vista previa». La URL del preview caduca:
  no se guarda; al reproducir se pide `https://api.deezer.com/track/<id>`. Crédito «Música de Deezer» (logo + nota de
  uso personal) en búsqueda, escena y franja sobre fotos. Botones: «Abrir en Deezer» (`deezer://www.deezer.com/track/<id>`
  y si no, el enlace web), búsqueda en Spotify (`open.spotify.com/search/<consulta>`) y YouTube (`results?search_query=`),
  con url_launcher en app externa (`AbridorEnlacesMusica` inyectable). AndroidManifest ya tenía las queries `https` y
  `deezer`; Info.plist ya tenía `deezer`. La música se adjunta como recuerdo (`elementos` tipo `musica` o foto con
  música), que ya se elige en cápsulas y momentos. Migración nueva `20261030000023` (sin aplicar): `musica_proveedor`
  admite `deezer`, Deezer con id numérico y `musica_preview_url` null. Sin paquetes nuevos. `flutter analyze` 0 issues,
  `flutter test` 388 en verde. Los registrantes de plugins aparecen modificados por finales de línea (no se restauran).
