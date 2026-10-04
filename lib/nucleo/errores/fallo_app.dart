/// Contrato base de los fallos de dominio que llevan un mensaje en español
/// para mostrar al usuario.
abstract interface class FalloApp implements Exception {
  String get codigo;
  String get mensaje;
}

/// Mensaje genérico cuando un error no tiene un mensaje específico.
const String kMensajeErrorInesperado =
    'Ocurrió un error inesperado. Inténtalo de nuevo.';

/// Devuelve el mensaje en español para [error] o, si no lo tiene, el genérico.
String mensajeParaUsuario(Object? error) {
  if (error is FalloApp) return error.mensaje;
  return kMensajeErrorInesperado;
}
