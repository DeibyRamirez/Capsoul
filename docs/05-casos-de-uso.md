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
| Ver recuerdo (visor publicación) | Usuario | `visor_publicacion_recuerdo.dart` | `RepositorioUrlsMedio` + `firmar-medio` |
| Editar recuerdo / nota | Propietario | `pantalla_editar_recuerdo.dart` | `actualizarMetadatos` / `actualizarContenidoTexto` |
| Importar foto/video desde galería | Usuario | `hoja_origen_medio.dart` | `importador_medios_dispositivo` + Cloudinary |
| Buscar y guardar música | Usuario | `pantalla_buscar_musica.dart` | `buscar-musica` + `RepositorioRecuerdosSupabase` |
| Añadir música a una foto | Usuario | `pantalla_guardar_recuerdo.dart` | Mismos metadatos `musica_*` en `elementos` |
| Escuchar preview (URL caducada) | Usuario | `escena_preview_musica.dart` | `refrescarPreview` + `actualizarMusicaPreview` |
| Escuchar preview / abrir plataformas | Usuario | visor / búsqueda música | `just_audio` + `abrir_plataformas_musica` |
| Subir avatar de perfil | Usuario | `pantalla_perfil.dart` | `firmar-subida` + `firmar-medio` (avatar) |

## Momentos

| Caso de uso | Actor | Pantalla | Repositorio / servicio |
|---|---|---|---|
| Ver feed de momentos | Usuario | `pantalla_momentos.dart` | `RepositorioMomentosSupabase.listar()` |
| Filtrar momentos en perfil | Usuario | `pantalla_perfil.dart` | `FiltroMomentos` (memoria) |
| Crear momento | Usuario | `pantalla_nuevo_momento.dart` | `RepositorioMomentosSupabase.crear()` |
| Ver detalle de momento | Usuario | `pantalla_detalle_momento.dart` | `RepositorioMomentosSupabase.obtener()` |
| Borrar momento | Autor | `pantalla_detalle_momento.dart` | `RepositorioMomentosSupabase.eliminar()` |

## Amistades

| Caso de uso | Actor | Pantalla | Repositorio / servicio |
|---|---|---|---|
| Ver amigos aceptados | Usuario | `pantalla_amigos.dart` | `rpc mis_amigos()` |
| Aceptar/rechazar solicitud | Usuario | `pantalla_amigos.dart` | `amistades` (update estado) |
| Buscar amigo por @ (exacto) | Usuario | `pantalla_amigos.dart` | `resolver_usuario_por_arroba` |
| Enviar solicitud de amistad | Usuario | `pantalla_amigos.dart` | `enviar_solicitud_amistad` |
| Elegir @ al registrarse | Visitante | `pantalla_registro.dart` | metadata `nombre_usuario` + trigger perfil |
| Completar @ (cuentas antiguas) | Usuario | `pantalla_elegir_nombre_usuario.dart` | `establecer_mi_nombre_usuario` |

## Cápsulas

| Caso de uso | Actor | Pantalla | Repositorio / servicio |
|---|---|---|---|
| Crear cápsula (destinatario = amigo) | Usuario | `pantalla_crear_capsula.dart` | `RepositorioCapsulasSupabase` + `capsula_destinatarios.usuario_id` |
| Compartir enlace de cápsula | Autor | detalle cápsula | `EnlaceCapsoul.capsula` + `share_plus` |
| Ver mis cápsulas | Autor | rutas `/capsulas` | `RepositorioCapsulasSupabase` |
| Ver cápsulas recibidas | Destinatario | `/capsulas/recibidas` | `rpc capsulas_recibidas()` |
| Abrir cápsula liberada | Destinatario | `pantalla_detalle_capsula.dart` | RLS + `firmar-medio` |
| Marcar como abierta | Destinatario | detalle cápsula | `rpc marcar_capsula_abierta()` |

## Herencias y retos

| Caso de uso | Actor | Pantalla / RPC |
|---|---|---|
| Crear herencia | Propietario | `pantalla_nueva_herencia.dart` · migración `000014` |
| Persona de confianza global | Propietario | `pantalla_seguridad_legado.dart` · `establecer_persona_confianza_legado` |
| Vincular cápsulas al legado | Propietario | Wizard herencia · `herencia_capsulas` |
| Confirmar herencia | Persona de confianza | RPC `confirmar_herencia()` |
| Ver y completar retos | Usuario | `pantalla_retos.dart` · `RepositorioRetosSupabase` |

## Notificaciones

| Caso de uso | Actor | Estado |
|---|---|---|
| Recibir push al liberar cápsula | Destinatario | FCM token en arranque; registro en `dispositivos_push` pendiente |
| Enviar avisos pendientes | Servidor | Edge Function `enviar-avisos` (desplegar + cron job 3) |
