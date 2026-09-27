import '../../../nucleo/errores/fallo_app.dart';

/// Fallo de autenticación con un [mensaje] en español para el usuario.
///
/// Los códigos siguen los de FirebaseAuthException, pero esta clase no
/// depende de Firebase para poder usarse desde cualquier capa.
class FalloAutenticacion implements FalloApp {
  const FalloAutenticacion._(this.codigo, this.mensaje);

  factory FalloAutenticacion.desdeCodigo(String codigo) {
    return FalloAutenticacion._(codigo, mensajeParaCodigo(codigo));
  }

  const FalloAutenticacion.desconocido()
      : codigo = codigoDesconocido,
        mensaje = kMensajeErrorInesperado;

  /// Código usado cuando el error no viene de Firebase Auth.
  static const String codigoDesconocido = 'desconocido';

  @override
  final String codigo;

  @override
  final String mensaje;

  bool get esUsuarioNoEncontrado => codigo == 'user-not-found';

  static String mensajeParaCodigo(String codigo) {
    return switch (codigo) {
      'invalid-email' => 'El correo electrónico no es válido.',
      'user-disabled' =>
        'Esta cuenta está deshabilitada. Escríbenos si crees que es un error.',
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' ||
      'INVALID_LOGIN_CREDENTIALS' =>
        'Correo o contraseña incorrectos.',
      'email-already-in-use' => 'Ya existe una cuenta con este correo.',
      'weak-password' =>
        'La contraseña es muy débil. Usa al menos 8 caracteres.',
      'too-many-requests' =>
        'Demasiados intentos. Espera unos minutos e inténtalo de nuevo.',
      'network-request-failed' =>
        'Sin conexión. Revisa tu internet e inténtalo de nuevo.',
      'operation-not-allowed' =>
        'El acceso con correo y contraseña no está habilitado.',
      'requires-recent-login' =>
        'Por seguridad, vuelve a iniciar sesión e inténtalo de nuevo.',
      _ => kMensajeErrorInesperado,
    };
  }

  @override
  String toString() => 'FalloAutenticacion($codigo): $mensaje';
}
