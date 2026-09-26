---
name: capsoul-flutter-architecture
description: >-
  Use when scaffolding or changing Capsoul Flutter feature layout, routing, or
  layering.
---
# Capsoul Flutter architecture

Use when scaffolding or changing Capsoul Flutter structure, features, routing, or layering.

## Goals
Keep a feature-first layout, thin UI, and clear boundaries so Sprint work stays reviewable against DoD.

## Layout (target)
```
lib/
  main.dart
  app.dart
  core/theme/
  core/router/
  features/<feature>/presentation/
  features/<feature>/domain/   # when models/use-cases appear
  features/<feature>/data/     # when Firebase repos appear
```

## Rules
1. One feature folder per product area: `home`, `moments`, `create`, `legacy`, `profile`, `shell`, later `auth`, `capsules`.
2. Screens live under `presentation/`. Widgets shared by one feature stay in that feature; cross-feature UI goes in `core/` or a shared `widgets/` only when reused twice.
3. The bottom `+` is not a tab with its own nav state: elevated action that opens Create (selector Video/Audio/Escribir/Foto). Prefer `go_router` + `StatefulShellRoute`; `NavigationBar` + index is OK for early MVP.
4. No Firebase SDK calls inside widgets. UI talks to controllers/notifiers; those call repositories.
5. Prefer composition over deep widget inheritance. Extract when a build method is hard to scan in one screenful.
6. Name files by role: `*_screen.dart`, `*_repository.dart`, `*_model.dart`.
7. Spanish UI copy only. Keep code identifiers in English.

## Checklist before merge
- Feature folder matches the epic/story
- Router entries exist for new screens
- No circular imports across features
- `flutter analyze` clean for touched files
