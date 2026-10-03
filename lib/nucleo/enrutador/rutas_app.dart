/// Rutas de go_router usadas en toda la app.
abstract final class RutasApp {
  static const String raiz = '/';
  static const String inicio = '/inicio';
  static const String momentos = '/momentos';
  static const String legado = '/legado';
  static const String yo = '/yo';
  static const String crear = '/crear';
  static const String crearVideo = '/crear/video';
  static const String crearAudio = '/crear/audio';
  static const String crearEscribir = '/crear/escribir';
  static const String crearFoto = '/crear/foto';

  static const String iniciarSesion = '/iniciar-sesion';
  static const String registro = '/registro';
  static const String recuperar = '/recuperar';
  static const String revisaTuCorreo = '/revisa-tu-correo';

  /// Contraseña nueva tras abrir el enlace de recuperación (hay sesión
  /// temporal).
  static const String nuevaContrasena = '/nueva-contrasena';

  static const Set<String> rutasAutenticacion = {
    iniciarSesion,
    registro,
    recuperar,
    revisaTuCorreo,
  };

  /// Ubicación de "Revisa tu correo" para [correo]. Con [reenviar] la
  /// pantalla reenvía el correo de confirmación al abrirse.
  static String revisaTuCorreoPara(String correo, {bool reenviar = false}) {
    return Uri(
      path: revisaTuCorreo,
      queryParameters: {
        'correo': correo,
        if (reenviar) 'reenviar': '1',
      },
    ).toString();
  }
}

/// Regla pura de redirección del enrutador:
/// - con sesión en [modoRecuperacion] (se abrió el enlace de recuperar
///   contraseña), todo va a [RutasApp.nuevaContrasena];
/// - [RutasApp.nuevaContrasena] fuera de ese modo no se puede abrir;
/// - sin sesión, toda ruta que no sea de autenticación va a
///   [RutasApp.iniciarSesion];
/// - con sesión, las rutas de autenticación (y `/`) van a [RutasApp.inicio].
String? resolverRedireccionAutenticacion({
  required bool sesionIniciada,
  required String ubicacion,
  bool modoRecuperacion = false,
}) {
  if (sesionIniciada && modoRecuperacion) {
    return ubicacion == RutasApp.nuevaContrasena
        ? null
        : RutasApp.nuevaContrasena;
  }
  if (ubicacion == RutasApp.nuevaContrasena) {
    return sesionIniciada ? RutasApp.inicio : RutasApp.iniciarSesion;
  }
  final esRutaAutenticacion = RutasApp.rutasAutenticacion.contains(ubicacion);
  if (!sesionIniciada) {
    return esRutaAutenticacion ? null : RutasApp.iniciarSesion;
  }
  if (esRutaAutenticacion || ubicacion == RutasApp.raiz) {
    return RutasApp.inicio;
  }
  return null;
}
