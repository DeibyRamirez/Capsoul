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
- Previstos: firebase_messaging, flutter_local_notifications, video_player, just_audio.
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
    perfil/{aplicacion,presentacion}                       # ControladorPerfil, PantallaPerfil (pestaña Yo)
    navegacion/presentacion/contenedor_navegacion.dart     # barra: Inicio | Momentos | + | Mi legado | Yo
    elementos/{aplicacion,datos,dominio,presentacion}      # LimitesMedios, captura foto/video/audio/nota, compresión, firma+subida
    capsulas/{aplicacion,datos,dominio,presentacion}       # crear, mis cápsulas, detalle (candado, cuenta regresiva, apertura)
    inicio/{aplicacion,datos,dominio,presentacion}         # Inicio del mockup con conteos reales (RepositorioResumenInicio)
    momentos/ crear/ legado/                               # presentacion/pantalla_*.dart
test/                                # espejo de lib/ (nucleo/, funcionalidades/) + ayudantes/ (falsos, app_prueba)
docs/arquitectura.md                 # ARQ-2 v2.0: Supabase + Cloudinary + FCM + Resend (4 diagramas Mermaid)
docs/modelo_er.{md,mmd,png}          # modelo ER del director, v1.3 con las correcciones aprobadas por el PO
supabase/migrations/                 # 20261002000001_capsoul_modelo_inicial.sql, 20261002000002_capsoul_programar_trabajos.sql
supabase/migrations/20261003000003_capsoul_limites_medios.sql  # límites, 10 elementos, cuota 200 MB (NO aplicada)
supabase/functions/firmar-subida/       # Edge Function Deno (index.ts + limites.ts + limites_test.ts), NO desplegada
supabase/pruebas/pruebas_rls_capsoul.sql  # pruebas manuales de RLS (psql)
supabase/pruebas/pruebas_limites_medios.sql  # pruebas de la 000003 (psql, Postgres local)
env/dev.json.example + env/README.md # plantilla de --dart-define-from-file
.cursor/skills/                      # skills del proyecto (capsoul-*)
```

- Rutas: `/inicio`, `/momentos`, `/legado`, `/yo`, `/crear` (+ `/crear/capsula|video|audio|escribir|foto`),
  `/capsulas` (+ `/capsulas/:id`),
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
  `expires_at` a 1 h); el autor ve sus propios medios antes de `fecha_apertura`.
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
| S4 | Ruta crítica de cápsulas + Security Rules | 🟡 En rama local `funcionalidad/capsulas` (sin push): elementos base, crear/detalle de cápsula, Inicio del mockup, migración 000003 y Edge Function `firmar-subida` como archivos; falta aprobación del PO para desplegar |
| S8 | Endurecer reglas + FCM | ⏳ |

## 6. Pendientes abiertos

Todo lo que toca un entorno requiere aprobación del PO (regla 7).

- [ ] PO: aplicar `…000002_capsoul_programar_trabajos.sql` (requiere extensiones `pg_cron` y `pg_net`, y en Vault
      `project_url` y `llave_cron`).
- [ ] Director: actualizar RF-05 en Drive si hace falta (no existe en el repo; la copia 02 v1.2 ya pide confirmación
      obligatoria y la pantalla "Revisa tu correo").
- [ ] Llamar `registrar_actividad()` (RPC) al abrir la app, para herencias por inactividad.
- [ ] PO: aprobar y desplegar `firmar-subida` (`supabase functions deploy firmar-subida --project-ref
      mslcdvcmfuqopfwojxvt`) con secretos `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET`, y
      aplicar `20261003000003_capsoul_limites_medios.sql`. Hasta entonces los medios muestran "subida no disponible";
      las notas de texto ya funcionan con la 000001.
- [ ] PO: revisar la rama `funcionalidad/capsulas` y autorizar push / PR a `develop`.
- [ ] `firmar-medio` para reproducir fotos/videos/audios (hoy el detalle muestra tarjetas sin reproducir).
- [ ] Limpiar en Cloudinary los medios huérfanos si falla el guardado tras subir (la app compensa solo en la BD).
- [ ] El tamaño declarado no lo puede imponer la firma de Cloudinary: valorar verificación posterior (webhook
      `notification_url` o revisión en `firmar-medio`).
- [ ] `miniatura_public_id` queda en null (eager crea la miniatura derivada; falta guardarla/servirla).
- [ ] Destinatarios de cápsula (campo visible y deshabilitado, "Próximamente").
- [ ] PO: el mockup de Inicio muestra la barra "Inicio | Momento | + | Historia | Yo"; se mantuvo la congelada en la
      skill UI ("Inicio | Momentos | + | Mi legado | Yo"). Decidir.
- [ ] `pruebas_rls_capsoul.sql` inserta una foto sin `bytes`: con la 000003 esa línea fallará por el check (esperado).
- [ ] iOS: verificar en Mac la compilación con camera/record (deployment target) y los permisos.
- [ ] Borrar `firestore.rules` y `firebase.json` y desactivar Firebase Auth/Firestore/Storage en la consola (decisión del PO).
- [ ] Edge Functions `firmar-subida`, `firmar-medio` y `enviar-avisos`.
- [ ] PO: probar en dispositivo lo que falta del flujo (login sin confirmar → reenviar; recuperar → enlace → nueva
      contraseña; editar nombre, cerrar sesión, sesión persistente). Registro e inicio de sesión con correo: OK.
- [ ] Vigilar el límite de Resend (plan gratuito, 100 correos/día) y el rate limit de correos de Supabase Auth.
- [ ] iOS: falta `ios/Runner/GoogleService-Info.plist` (necesario para FCM).
- [ ] Actualizar remoto local: `git remote set-url origin https://github.com/DeibyRamirez/Capsoul.git`.
- [ ] S1-07: instalar packs oficiales de skills (ver `.cursor/skills/README.md`).
- [ ] FCM (`firebase_messaging`) · reproductores (video_player/just_audio) · CI.
- [ ] Revisar si se abre PR `develop` → `main`.

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
- **2026-10-03** Fecha de apertura: solo días futuros (desde mañana), a las 8:00 hora local. Material en español
  (`flutter_localizations`, `es_CO`).
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
