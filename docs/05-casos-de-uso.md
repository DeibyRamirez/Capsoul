# Capsoul · Casos de uso

## Leyenda

- **Actor:** quién inicia el caso.
- **Pantalla:** widget principal en `presentacion/`.
- **Repositorio / RPC:** capa de datos.

## Autenticación y perfil

| Caso de uso | Actor | Pantalla | Repositorio / servicio |
|---|---|---|---|
| Registrarse | Visitante | `pantalla_registro.dart` | `RepositorioAutenticacionSupabase` |
| Iniciar sesión | Usuario | `pantalla_iniciar_sesion.dart` | `RepositorioAutenticacionSupabase` |
| Confirmar correo | Usuario | `pantalla_revisa_tu_correo.dart` | Supabase Auth (enlace) |
| Recuperar contraseña | Usuario | `pantalla_recuperar_contrasena.dart` | `RepositorioAutenticacionSupabase` |
| Ver y editar perfil | Usuario autenticado | `pantalla_perfil.dart` | `RepositorioUsuariosSupabase`, `ControladorPerfil` |
| Cerrar sesión | Usuario autenticado | `pantalla_perfil.dart` | `RepositorioAutenticacionSupabase` |

## Recuerdos y medios

| Caso de uso | Actor | Pantalla | Repositorio / servicio |
|---|---|---|---|
| Capturar foto | Usuario | `pantalla_capturar_foto.dart` | `RepositorioMediosCloudinary` |
| Grabar audio/video | Usuario | pantallas en `elementos/` | `RepositorioMediosCloudinary` |
| Escribir nota | Usuario | `pantalla_escribir_nota.dart` | `RepositorioRecuerdosSupabase` |
| Ver banco de recuerdos | Usuario | `pantalla_recuerdos.dart` | `RepositorioRecuerdosSupabase` |
| Ver detalle de recuerdo | Usuario | `pantalla_detalle_recuerdo.dart` | `RepositorioUrlsMedio` + `firmar-medio` |

## Momentos

| Caso de uso | Actor | Pantalla | Repositorio / servicio |
|---|---|---|---|
| Ver feed de momentos | Usuario | `pantalla_momentos.dart` | `RepositorioMomentosSupabase.listar()` |
| Filtrar momentos en perfil | Usuario | `pantalla_perfil.dart` | `FiltroMomentos` (memoria) |
| Crear momento | Usuario | `pantalla_nuevo_momento.dart` | `RepositorioMomentosSupabase.crear()` |
| Ver detalle de momento | Usuario | `pantalla_detalle_momento.dart` | `RepositorioMomentosSupabase.obtener()` |
| Borrar momento | Autor | `pantalla_detalle_momento.dart` | `RepositorioMomentosSupabase.eliminar()` |

## Cápsulas

| Caso de uso | Actor | Pantalla | Repositorio / servicio |
|---|---|---|---|
| Crear cápsula | Usuario | `pantalla_crear_capsula.dart` | `RepositorioCapsulasSupabase` |
| Ver mis cápsulas | Autor | rutas `/capsulas` | `RepositorioCapsulasSupabase` |
| Ver cápsulas recibidas | Destinatario | (pendiente UI dedicada) | `rpc capsulas_recibidas()` |
| Abrir cápsula liberada | Destinatario | `pantalla_detalle_capsula.dart` | RLS + `firmar-medio` |
| Marcar como abierta | Destinatario | detalle cápsula | `rpc marcar_capsula_abierta()` |

## Herencias y retos (backlog)

| Caso de uso | Actor | Estado |
|---|---|---|
| Crear herencia | Propietario | `pantalla_legado.dart` placeholder |
| Confirmar herencia | Persona de confianza | RPC `confirmar_herencia()` en SQL |
| Participar en reto | Amigo | Tablas `retos`, `reto_participantes` en ER |

## Notificaciones

| Caso de uso | Actor | Estado |
|---|---|---|
| Recibir push al liberar cápsula | Destinatario | FCM token en arranque; registro en `dispositivos_push` pendiente |
| Enviar avisos pendientes | Servidor | Edge Function `enviar-avisos` pendiente |
