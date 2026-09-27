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

  static const Set<String> rutasAutenticacion = {
    iniciarSesion,
    registro,
    recuperar,
  };
}

/// Regla pura de redirección del enrutador:
/// - sin sesión, toda ruta que no sea de autenticación va a
///   [RutasApp.iniciarSesion];
/// - con sesión, las rutas de autenticación (y `/`) van a [RutasApp.inicio].
String? resolverRedireccionAutenticacion({
  required bool sesionIniciada,
  required String ubicacion,
}) {
  final esRutaAutenticacion = RutasApp.rutasAutenticacion.contains(ubicacion);
  if (!sesionIniciada) {
    return esRutaAutenticacion ? null : RutasApp.iniciarSesion;
  }
  if (esRutaAutenticacion || ubicacion == RutasApp.raiz) {
    return RutasApp.inicio;
  }
  return null;
}
