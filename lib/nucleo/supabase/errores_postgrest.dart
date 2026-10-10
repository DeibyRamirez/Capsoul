import '../infraestructura/traductor_errores_backend.dart';

/// Alias de compatibilidad. Preferir [TraductorErroresBackend].
abstract final class ErroresPostgrest {
  static const String permisoDenegado = TraductorErroresBackend.permisoDenegado;
  static const Set<String> sesionInvalida =
      TraductorErroresBackend.sesionInvalida;

  static String? tablaDeViolacionRls(String mensaje) =>
      TraductorErroresBackend.tablaDeViolacionRls(mensaje);
}
