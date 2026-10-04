# Capsoul · Patrones y convenciones

## Arquitectura en capas

1. **Presentación** — widgets delgados; sin `Supabase.instance` ni HTTP directo.
2. **Aplicación** — Riverpod (`Notifier`, `FutureProvider`, `StreamProvider`).
3. **Dominio** — entidades y contratos; sin imports de Flutter ni Supabase.
4. **Datos** — implementaciones concretas y acceso a tablas.

Dependencias: `presentacion → aplicacion → dominio ← datos`.

## Riverpod

| Patrón | Ejemplo |
|---|---|
| Repositorio inyectable | `proveedorRepositorioMomentos` |
| Lista async | `proveedorMomentos` (`FutureProvider`) |
| Estado de formulario | `ControladorNuevoMomento` extends `Notifier` |
| Filtro UI | `proveedorFiltroMomentos` |
| Perfil en tiempo real | `proveedorPerfilUsuarioActual` (`StreamProvider`) |

En pruebas se sobreescriben providers con implementaciones fake (`mocktail`).

## Enrutamiento (go_router)

- Rutas en español: `/iniciar-sesion`, `/momentos/nuevo`.
- `StatefulShellRoute` conserva estado de las 4 pestañas.
- Crear (`/crear`) es `push`, no rama del shell.
- Constantes en `RutasApp` (`nucleo/enrutador/rutas_app.dart`).

## Nomenclatura (español)

| Elemento | Convención | Ejemplo |
|---|---|---|
| Archivos | snake_case | `pantalla_perfil.dart` |
| Clases | PascalCase español | `PantallaPerfil` |
| Variables / métodos | camelCase español | `nombreVisible`, `listar()` |
| Tablas SQL | snake_case sin ñ | `capsula_destinatarios` |
| En inglés solo | APIs de librerías | `build`, `dispose`, `main` |

## Manejo de errores

- Fallos de dominio: `FalloApp` con subclases (`FalloMomento`, `FalloAutenticacion`, …).
- UI: `mensajeParaUsuario(error)` y `mostrarAvisoError`.
- Arranque: `AppErrorArranque` si Supabase no configura.

## UI / tema

- Colores: `ColoresApp` (`primario` #1B2A4A, `acento` #3D6B9A).
- Radios: `TemaApp.radioPequeno` … `radioGrande` (12–20).
- Material 3: `NavigationBar`, `FilledButton`, `Card`.
- Skill: `.cursor/skills/capsoul-ui-design-system/SKILL.md`.

## Pruebas

- Espejo de `lib/` en `test/`.
- Repositorios mockeados vía `ProviderScope` overrides.
- `AccesoTablas*` como interfaces para simular PostgREST.

## Reglas de agente / PO

- Sin commit/push sin autorización explícita.
- Cambios en entornos (SQL, deploy, consolas) con aprobación PO.
- Skills obligatorias según tarea: arquitectura, Supabase, Cloudinary, MCP.

## Anti-patrones (evitar)

- Llamar `FirebaseMessaging.instance.getToken()` sin comprobar que Firebase inicializó.
- Hexadecimales sueltos en widgets de funcionalidades.
- Importaciones circulares entre carpetas de `funcionalidades/`.
- Lógica de negocio compleja dentro de `build()`.
