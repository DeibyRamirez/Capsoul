import 'capsula.dart';
import 'capsula_recibida.dart';
import 'nueva_capsula.dart';

/// Acceso a las cápsulas del usuario. Las implementaciones traducen los
/// errores a [FalloCapsula].
abstract interface class RepositorioCapsulas {
  /// Guarda la cápsula programada con los recuerdos elegidos (ya existen
  /// en `elementos`). Devuelve el id de la cápsula.
  Future<String> crearCapsula(NuevaCapsula nueva);

  /// Cápsulas creadas por el usuario, de la más reciente a la más antigua.
  Future<List<Capsula>> listarMisCapsulas();

  /// Cápsula con sus elementos o `null` si no existe o RLS la oculta.
  Future<Capsula?> obtenerCapsula(String id);

  /// Cápsulas donde el usuario actual es destinatario.
  Future<List<CapsulaRecibida>> listarRecibidas();

  /// Marca la cápsula como abierta por el destinatario (solo si está liberada).
  Future<void> marcarAbierta(String idCapsula);

  /// Marca el aviso de una cápsula compartida como visto (`leida_en`).
  Future<void> marcarAvisoLeido(String idCapsula);

  Future<void> actualizarMetadatosCapsula(
    String id, {
    required String titulo,
    String? mensaje,
    required DateTime fechaApertura,
  });

  /// Actualiza metadatos, recuerdos enlazados y destinatarios (cápsula editable).
  Future<void> actualizarCapsulaEditable(
    String id, {
    required String titulo,
    String? mensaje,
    required DateTime fechaApertura,
    required List<String> idsRecuerdosOrdenados,
    required List<String> destinatariosUsuarioIds,
  });

  Future<void> cancelarCapsula(String id);

  Future<void> eliminarCapsula(String id);
}
