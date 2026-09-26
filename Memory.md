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

## 3. Stack y dependencias

- Flutter 3.47.2 / Dart 3.13.2.
- `go_router ^16.2.0`, `firebase_core ^4.1.0`, `firebase_auth ^6.0.2`, `cloud_firestore ^6.0.1`,
  `firebase_storage ^13.0.1`, `flutter_lints`.
- Previstos (ARQ-1): flutter_riverpod, camera/image_picker, record, video_player, just_audio, video_compress,
  flutter_image_compress, firebase_messaging, flutter_local_notifications, Crashlytics, App Check,
  mocktail, fake_cloud_firestore. CI con GitHub Actions (+ Codemagic para iOS).

## 4. Arquitectura actual

```
lib/
  main.dart                      # arranque + FirebaseBootstrap
  app.dart                       # CapsoulApp (MaterialApp.router)
  core/
    theme/app_colors.dart        # primario #1B2A4A, acento #3D6B9A
    theme/app_theme.dart         # ThemeData, radios 12–20
    router/app_router.dart       # go_router, StatefulShellRoute.indexedStack (4 ramas) + /create
    firebase/firebase_bootstrap.dart  # init diferida; se salta si falta firebase_options.dart
  features/
    shell/presentation/main_shell.dart   # barra: Inicio | Momentos | + | Mi legado | Yo
    home/ moments/ create/ legacy/ profile/   # presentation/* (pantallas base)
test/widget_test.dart            # "CapsoulApp muestra shell de Inicio"
.cursor/skills/                  # skills del proyecto (capsoul-*)
```

- El botón `+` no es una pestaña: hace push de `/create` (Video, Audio, Escribir, Foto).
- UI en español.

## 5. Estado por sprint

| Sprint | Objetivo | Estado |
|---|---|---|
| S1 | Cimientos: estructura, tema, navegación, init Firebase, org, skills | ✅ Terminado (en `develop`, validación de Capsoul en ClickUp y Linear) |
| S2 | Autenticación (Firebase Auth) | ⏳ Por planificar |
| S4 | Ruta crítica de cápsulas + Security Rules | ⏳ |
| S8 | Endurecer reglas + FCM | ⏳ |

## 6. Pendientes abiertos

- [ ] `flutterfire configure` (PO, requiere proyecto Firebase): genera `firebase_options.dart`,
      `google-services.json` y `GoogleService-Info.plist`.
- [ ] Actualizar remoto local: `git remote set-url origin https://github.com/DeibyRamirez/Capsoul.git`.
- [ ] S1-07: instalar packs oficiales de skills.sh (ver `.cursor/skills/README.md`).
- [ ] Contrastar `.cursor/skills` con ClickUp DOC-04 (quedó bloqueado por el límite diario de ClickUp).
- [ ] `functions/`, `firebase.json`, `.firebaserc`.
- [ ] Riverpod y paquetes multimedia · FCM · CI · Security Rules (S4/S8).
- [ ] Revisar si se abre PR `develop` → `main` al cerrar S1.

## 7. Decisiones (ADR corto)

- **2026-09-25** Flutter (una base de código para Android e iOS) + Firebase serverless (ARQ-1, Linear DEV-89).
- **2026-09-25** go_router con `StatefulShellRoute` para conservar el estado de cada pestaña.
- **2026-09-25** Firebase se inicializa de forma diferida para que la app corra sin `firebase_options.dart`.
- **2026-09-26** Renombre de Capsould a Capsoul (org `com.capsoul`, paquete `capsoul`).
- **2026-09-26** Commits en español, incluido el tipo.

## 8. Bitácora

- **2026-09-25** S1: estructura, tema, router, pantallas base y bootstrap de Firebase. Org `com.example.capsould` → `com.capsould`.
- **2026-09-26** Renombre a Capsoul. Push de S1 a `develop` (9 commits, f375fb4…43984f5).
- **2026-09-26** Incidente: el commit `43984f5` corrompió caracteres en Info.plist, my_application.cc,
  main.cpp y README (script de reemplazo defectuoso). Capsoul lo detectó (FAIL). Corregido en `11e6977`.
  PO verificó la app en debug.
- **2026-09-26** Skills del proyecto exportadas a `.cursor/skills/` (`1079f8c`). S1 cerrado en `develop`.
- **2026-09-26** Se crea este `Memory.md`.
