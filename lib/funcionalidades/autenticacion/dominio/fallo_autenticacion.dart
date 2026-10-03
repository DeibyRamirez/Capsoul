import '../../../nucleo/errores/fallo_app.dart';

/// Fallo de autenticación con un [mensaje] en español para el usuario.
///
/// Los códigos siguen los `error_code` de Supabase Auth (GoTrue), pero esta
/// clase no depende de Supabase para poder usarse desde cualquier capa.
class FalloAutenticacion implements FalloApp {
  const FalloAutenticacion._(this.codigo, this.mensaje);

  factory FalloAutenticacion.desdeCodigo(String codigo) {
    return FalloAutenticacion._(codigo, mensajeParaCodigo(codigo));
  }

  const FalloAutenticacion.desconocido()
      : codigo = codigoDesconocido,
        mensaje = kMensajeErrorInesperado;

  /// Código usado cuando el error no trae un código reconocible.
  static const String codigoDesconocido = 'desconocido';

  /// Código propio para errores de red (Supabase no envía `error_code`).
  static const String codigoSinRed = 'sin_red';

  /// Código propio para HTTP 429 sin `error_code`.
  static const String codigoDemasiadosIntentos = 'over_request_rate_limit';

  @override
  final String codigo;

  @override
  final String mensaje;

  /// Código de Supabase Auth cuando la cuenta existe pero no confirmó el
  /// correo.
  static const String codigoCorreoNoConfirmado = 'email_not_confirmed';

  bool get esUsuarioNoEncontrado => codigo == 'user_not_found';

  bool get esCorreoNoConfirmado => codigo == codigoCorreoNoConfirmado;

  static String mensajeParaCodigo(String codigo) {
    return switch (codigo) {
      'email_address_invalid' ||
      'validation_failed' =>
        'El correo electrónico no es válido.',
      'user_banned' =>
        'Esta cuenta está deshabilitada. Escríbenos si crees que es un error.',
      'invalid_credentials' ||
      'user_not_found' =>
        'Correo o contraseña incorrectos.',
      'email_not_confirmed' =>
        'Confirma tu correo antes de iniciar sesión. Revisa tu bandeja de '
            'entrada.',
      'user_already_exists' ||
      'email_exists' =>
        'Ya existe una cuenta con este correo.',
      'weak_password' =>
        'La contraseña es muy débil. Usa al menos 8 caracteres.',
      'same_password' =>
        'La nueva contraseña debe ser distinta de la anterior.',
      'over_request_rate_limit' ||
      'over_email_send_rate_limit' =>
        'Demasiados intentos. Espera unos minutos e inténtalo de nuevo.',
      codigoSinRed => 'Sin conexión. Revisa tu internet e inténtalo de nuevo.',
      'signup_disabled' ||
      'email_provider_disabled' =>
        'El acceso con correo y contraseña no está habilitado.',
      'session_not_found' ||
      'session_expired' ||
      'refresh_token_not_found' ||
      'refresh_token_already_used' =>
        'Tu sesión expiró. Vuelve a iniciar sesión.',
      'reauthentication_needed' =>
        'Por seguridad, vuelve a iniciar sesión e inténtalo de nuevo.',
      _ => kMensajeErrorInesperado,
    };
  }

  @override
  String toString() => 'FalloAutenticacion($codigo): $mensaje';
}
