---
name: capsoul-flutter-architecture
description: >-
  Usar cuando se cree o cambie la estructura de funcionalidades, el
  enrutamiento o la separación de capas de la app Flutter de Capsoul.
---
# Capsoul · Arquitectura Flutter

Usar al crear funcionalidades, pantallas, rutas o capas nuevas.

## Objetivo
Estructura por funcionalidades, UI delgada y límites claros para que el trabajo del sprint sea revisable
contra la DoD.

## Estructura
```
lib/
  main.dart                  # obligatorio de Flutter
  app_capsoul.dart           # AppCapsoul (MaterialApp.router)
  nucleo/                    # compartido: errores, firebase (solo FCM), supabase, enrutador, tema, componentes
  funcionalidades/<funcionalidad>/
    presentacion/            # pantallas y componentes
    aplicacion/              # proveedores y controladores Riverpod
    dominio/                 # modelos, interfaces de repositorio, fallos
    datos/                   # implementaciones con Supabase / Cloudinary
test/                        # espejo de lib/ + ayudantes/
supabase/migrations/         # SQL versionado (ver capsoul-supabase-postgres-sql)
```

## Reglas
1. Una carpeta por área de producto: `inicio`, `momentos`, `crear`, `legado`, `perfil`, `navegacion`,
   `autenticacion`, `usuarios`, luego `capsulas`, `herencias`, `retos`.
2. Pantallas en `presentacion/` (`pantalla_*.dart`); componentes de una sola funcionalidad se quedan en ella;
   lo reutilizado por dos o más va a `nucleo/componentes/`.
3. El `+` de la barra no es pestaña: abre `/crear` (Video, Audio, Escribir, Foto) con `context.push`.
   go_router + `StatefulShellRoute` para conservar el estado de cada pestaña.
4. Ninguna llamada a Supabase, Cloudinary o Firebase dentro de widgets: la UI habla con controladores y estos
   con repositorios inyectados por providers.
5. Composición antes que herencia profunda; extraer cuando un `build` no se lea en una pantalla.
6. Archivos por rol: `pantalla_*.dart`, `repositorio_*.dart`, `controlador_*.dart`, `proveedores_*.dart`.
7. **Todo en español**: archivos, carpetas, clases, métodos, variables, rutas (`/inicio`, `/iniciar-sesion`) y
   textos. Identificadores sin tildes ni ñ (`contrasena`). Solo quedan en inglés las APIs de Flutter y
   librerías (`build`, `createState`, `dispose`) y los archivos obligatorios/generados.
8. Configuración sensible por `--dart-define` (`SUPABASE_URL`, `SUPABASE_ANON_KEY`); nunca claves en el repo.

## Lista antes de fusionar
- La carpeta coincide con la épica/historia
- Hay rutas para las pantallas nuevas y la redirección por sesión sigue funcionando
- Sin importaciones circulares entre funcionalidades
- `flutter analyze` limpio

## Fuentes
- Flutter, "Guide to app architecture": https://docs.flutter.dev/app-architecture/guide
- go_router, `StatefulShellRoute`: https://pub.dev/documentation/go_router/latest/go_router/StatefulShellRoute-class.html
- Riverpod: https://riverpod.dev/docs/introduction/why_riverpod
