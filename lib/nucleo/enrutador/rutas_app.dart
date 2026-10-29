import '../enlaces/enlace_capsoul.dart';

/// Rutas de go_router usadas en toda la app.
abstract final class RutasApp {
  static const String raiz = '/';
  static const String inicio = '/inicio';
  static const String avisos = '/avisos';
  static const String momentos = '/momentos';
  static const String nuevoMomento = '/momentos/nuevo';
  static const String legado = '/legado';
  static const String legadoNuevaHerencia = '/legado/nueva';
  static const String legadoInstrucciones = '/legado/instrucciones';
  static const String legadoSeguridad = '/legado/seguridad';

  static String detalleHerenciaDe(String id) =>
      '$legado/herencia/${Uri.encodeComponent(id)}';
  static const String yo = '/yo';
  static const String amigos = '/yo/amigos';
  static const String crear = '/crear';
  static const String crearVideo = '/crear/video';
  static const String crearAudio = '/crear/audio';
  static const String crearEscribir = '/crear/escribir';
  static const String crearFoto = '/crear/foto';
  static const String crearMusica = '/crear/musica';
  static const String elegirMusica = '/recuerdos/elegir-musica';
  static const String crearCapsula = '/crear/capsula';
  static const String capsulas = '/capsulas';
  static const String capsulasRecibidas = '/capsulas/recibidas';
  static const String recuerdos = '/recuerdos';
  static const String retos = '/retos';
  static const String guardarRecuerdo = '/recuerdos/guardar';
  static const String elegirRecuerdos = '/recuerdos/elegir';

  static const String iniciarSesion = '/iniciar-sesion';
  static const String registro = '/registro';
  static const String recuperar = '/recuperar';
  static const String revisaTuCorreo = '/revisa-tu-correo';

  /// Contraseña nueva tras abrir el enlace de recuperación (hay sesión
  /// temporal).
  static const String nuevaContrasena = '/nueva-contrasena';
  static const String elegirNombreUsuario = '/elegir-usuario';

  static const Set<String> rutasAutenticacion = {
    iniciarSesion,
    registro,
    recuperar,
    revisaTuCorreo,
  };

  /// Ubicación del detalle de la cápsula [id].
  static String detalleCapsulaDe(String id) =>
      '$capsulas/${Uri.encodeComponent(id)}';

  static String editarCapsulaDe(String id) => '${detalleCapsulaDe(id)}/editar';

  /// Deep link fase 1: capsoul://capsula/{id}
  static String enlaceCapsulaDe(String id) => EnlaceCapsoul.capsula(id);

  /// Ubicación del detalle del momento [id].
  static String detalleMomentoDe(String id) =>
      '$momentos/${Uri.encodeComponent(id)}';

  static String editarMomentoDe(String id) => '${detalleMomentoDe(id)}/editar';

  /// Edición/gestión del recuerdo [id].
  static String editarRecuerdoDe(String id) =>
      '$recuerdos/${Uri.encodeComponent(id)}/editar';

  /// Compatibilidad: enlaces antiguos al detalle abren la edición.
  static String detalleRecuerdoDe(String id) => editarRecuerdoDe(id);

  /// Ubicación de "Revisa tu correo" para [correo]. Con [reenviar] la
  /// pantalla reenvía el correo de confirmación al abrirse.
  static String revisaTuCorreoPara(String correo, {bool reenviar = false}) {
    return Uri(
      path: revisaTuCorreo,
      queryParameters: {'correo': correo, if (reenviar) 'reenviar': '1'},
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

/// Si falta `nombre_usuario`, obliga a [RutasApp.elegirNombreUsuario].
///
/// Con [perfilCargando], no redirige hasta conocer el perfil (evita mandar a
/// inicio con caché desactualizada tras fijar el @).
String? resolverRedireccionNombreUsuario({
  required bool sesionIniciada,
  required String ubicacion,
  required bool necesitaNombreUsuario,
  bool perfilCargando = false,
}) {
  if (!sesionIniciada) return null;
  if (perfilCargando) return null;
  if (ubicacion == RutasApp.elegirNombreUsuario) {
    return necesitaNombreUsuario ? null : RutasApp.inicio;
  }
  if (necesitaNombreUsuario) return RutasApp.elegirNombreUsuario;
  return null;
}
