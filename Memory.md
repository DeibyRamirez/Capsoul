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
5. Seguir las skills del repo en `.cursor/skills/` (arquitectura, UI, Firebase, Firestore/Storage, código limpio, DoD).
6. **Idioma: todo el código en español**, el nuevo y el existente: archivos `.dart` (snake_case), carpetas, clases,
   funciones, variables, parámetros, providers, rutas de go_router, comentarios, textos de UI y campos de Firestore.
   Solo quedan en inglés: archivos obligatorios de Flutter (`main.dart`, sufijo `_test.dart`, `pubspec.yaml`,
   `analysis_options.yaml`), archivos de plataforma (`android/`, `ios/`, `linux/`, `windows/`, `macos/`, `web/`),
   generados (`lib/firebase_options.dart`, `google-services.json`, `GoogleService-Info.plist`) y las APIs de
   Flutter/Firebase/Riverpod/go_router (`build`, `createState`, `dispose`, `main()`, `ref`, `state`…).
   **Commits totalmente en español** (ver regla 2). Esta regla prevalece sobre la línea "Keep code identifiers in
   English" de las skills `capsoul-flutter-architecture` y `capsoul-flutter-clean-code`.

## 3. Stack y dependencias

- Flutter 3.47.2 / Dart 3.13.2.
- `go_router ^16.2.0`, `firebase_core ^4.1.0`, `firebase_auth ^6.0.2`, `cloud_firestore ^6.0.1`,
  `firebase_storage ^13.0.1`, `flutter_riverpod ^3.4.3`, `flutter_lints`.
- Dev: `mocktail ^1.0.5`, `fake_cloud_firestore ^4.3.0`.
- Previstos (ARQ-1): camera/image_picker, record, video_player, just_audio, video_compress,
  flutter_image_compress, firebase_messaging, flutter_local_notifications, Crashlytics, App Check.
  CI con GitHub Actions (+ Codemagic para iOS).

## 4. Arquitectura actual

Diagrama completo (ARQ-2): `docs/arquitectura.md`.

```
lib/
  main.dart                          # arranque: inicializarFirebase() + ProviderScope(AppCapsoul)
  app_capsoul.dart                   # AppCapsoul (MaterialApp.router)
  firebase_options.dart              # generado por flutterfire (capsoul-ebea3), no se edita
  nucleo/
    errores/fallo_app.dart           # FalloApp, mensajeParaUsuario()
    firebase/arranque_firebase.dart  # inicializarFirebase()
    firebase/app_error_arranque.dart # AppErrorArranque (si Firebase no inicia)
    enrutador/rutas_app.dart         # RutasApp + resolverRedireccionAutenticacion()
    enrutador/enrutador_app.dart     # proveedorEnrutadorApp, StatefulShellRoute (4 ramas) + /crear
    tema/colores_app.dart            # ColoresApp: primario #1B2A4A, acento #3D6B9A
    tema/tema_app.dart               # TemaApp.claro, radios 12-20
    componentes/                     # BotonPrincipal, mostrarAvisoError/Informativo
  funcionalidades/
    autenticacion/{aplicacion,datos,dominio,presentacion}  # RepositorioAutenticacion(+Firebase), pantallas
    usuarios/{aplicacion,datos,dominio}                    # RepositorioUsuarios(+Firestore), PerfilUsuario
    perfil/{aplicacion,presentacion}                       # ControladorPerfil, PantallaPerfil (pestaña Yo)
    navegacion/presentacion/contenedor_navegacion.dart     # barra: Inicio | Momentos | + | Mi legado | Yo
    inicio/ momentos/ crear/ legado/                       # presentacion/pantalla_*.dart
test/                                # espejo de lib/ (nucleo/, funcionalidades/) + ayudantes/ (falsos, app_prueba)
docs/arquitectura.md                 # ARQ-2
.cursor/skills/                      # skills del proyecto (capsoul-*)
```

- Rutas: `/inicio`, `/momentos`, `/legado`, `/yo`, `/crear` (+ `/crear/video|audio|escribir|foto`),
  `/iniciar-sesion`, `/registro`, `/recuperar`. Sin sesión solo rutas de autenticación; con sesión, el contenedor.
- El botón `+` no es una pestaña: hace push de `/crear` (Video, Audio, Escribir, Foto).
- Firestore: `usuarios/{uid}` con `nombreVisible`, `correo`, `fotoUrl` (null), `creadoEn` (serverTimestamp).
  Reglas en `firestore.rules`: solo el dueño lee/escribe; todo lo demás denegado.
- UI en español.

## 5. Estado por sprint

| Sprint | Objetivo | Estado |
|---|---|---|
| S1 | Cimientos: estructura, tema, navegación, init Firebase, org, skills | ✅ Terminado (en `develop`, validación de Capsoul en ClickUp y Linear) |
| S2 | Identidad y autenticación (registro, inicio de sesión, recuperar, sesión, perfil, reglas) | 🟡 Implementado y verificado localmente (analyze 0, 57 tests, apk debug); **sin commit**, falta prueba del PO en emulador |
| S4 | Ruta crítica de cápsulas + Security Rules | ⏳ |
| S8 | Endurecer reglas + FCM | ⏳ |

## 6. Pendientes abiertos

- [ ] **Commit y push** de la migración al español, el cierre de Firebase, el S2 y ARQ-2 (solo con autorización del PO;
      mensajes propuestos en el reporte del 2026-09-26).
- [ ] PO: probar el flujo real en emulador/dispositivo contra `capsoul-ebea3` (registro, verificación, inicio de sesión,
      recuperar, editar nombre, cerrar sesión, sesión persistente).
- [ ] PO: activar el proveedor **Email/Password** en Firebase Console → Authentication si no está activo.
- [ ] PO: desplegar `firestore.rules` (`firebase deploy --only firestore:rules`).
- [ ] iOS: falta `ios/Runner/GoogleService-Info.plist` si no se generó con `flutterfire configure`.
- [ ] Decidir si se commitea `lib/firebase_options.dart` (claves públicas de cliente; hoy está en el índice sin commit).
- [ ] Actualizar las skills que dicen "Keep code identifiers in English" para reflejar la regla de idioma (regla 6).
- [ ] Actualizar remoto local: `git remote set-url origin https://github.com/DeibyRamirez/Capsoul.git`.
- [ ] S1-07: instalar packs oficiales de skills.sh (ver `.cursor/skills/README.md`).
- [ ] Contrastar `.cursor/skills` con ClickUp DOC-04 (quedó bloqueado por el límite diario de ClickUp).
- [ ] `functions/` y `.firebaserc` (`firebase.json` ya existe con Firestore rules).
- [ ] Paquetes multimedia · FCM · CI · Security Rules de cápsulas y Storage (S4/S8).
- [ ] Revisar si se abre PR `develop` → `main` al cerrar S1.

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
