---
name: capsoul-flutter-clean-code
description: >-
  Usar cuando se escriba o revise código Dart/Flutter de Capsoul: principios,
  patrones, legibilidad, pruebas y mantenibilidad.
---
# Capsoul · Código limpio en Flutter

## Principios
1. Una responsabilidad por clase/archivo (pantalla ≠ repositorio ≠ modelo).
2. Depender de abstracciones en los límites (interfaces de repositorio) e inyectarlas con providers.
3. Modelos inmutables (`final`, `copiarCon`, `==`/`hashCode`).
4. Nulos explícitos; nada de `!` sin una invariante demostrada.
5. Efectos secundarios en los bordes (Supabase, Cloudinary, plugins); lógica pura en dominio.

## Patrones de Capsoul
- Carpetas por funcionalidad y capas presentación / aplicación / dominio / datos
- Repositorios con Supabase detrás de interfaces; adaptadores delgados para el SDK
- Navegación dirigida por el enrutador (go_router) y la sesión (`onAuthStateChange`)
- Estado unidireccional con Riverpod (un solo gestor de estado)
- Errores explícitos (`try/catch`) traducidos a fallos de dominio con mensaje en español y estados
  cargando / datos / error / vacío

## Prácticas de Flutter
1. Constructores `const` siempre que se pueda.
2. `Key` estables en listas.
3. `dispose` de controladores y suscripciones.
4. No usar `BuildContext` tras un `await` sin comprobar `mounted`.
5. `build()` simple: calcular fuera.
6. Pruebas de widgets para la UI crítica y unitarias (mocktail o falsos) para repositorios y mapeos.

## Barra de revisión
- Los nombres dicen la intención, **en español** (sin tildes ni ñ en identificadores)
- Sin código muerto ni bloques comentados
- Textos de UI en español
- Sin claves ni secretos en el código
- Coherente con las skills de arquitectura, UI y datos

## Fuentes
- Effective Dart: https://dart.dev/effective-dart
- Flutter, "Testing": https://docs.flutter.dev/testing/overview
- mocktail: https://pub.dev/packages/mocktail
