import 'amigo.dart';
import 'usuario_resuelto.dart';

abstract interface class RepositorioAmistades {
  Future<List<Amigo>> listarAmigos();

  Future<List<SolicitudAmistad>> listarSolicitudesPendientes();

  Future<void> aceptarSolicitud(String amistadId);

  Future<void> rechazarSolicitud(String amistadId);

  /// Búsqueda exacta por @ (sin listar usuarios).
  Future<UsuarioResuelto?> resolverPorArroba(String arroba);

  Future<void> enviarSolicitudAmistad(String receptorUsuarioId);

  /// Token opaco para `capsoul://amistad/{token}` (compatibilidad).
  Future<String> crearInvitacionEnlace();

  Future<void> aceptarInvitacion(String token);
}
