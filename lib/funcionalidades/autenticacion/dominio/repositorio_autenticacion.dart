import 'usuario_app.dart';

/// Contrato de autenticación. Las implementaciones lanzan
/// [FalloAutenticacion] cuando algo sale mal.
abstract interface class RepositorioAutenticacion {
  /// Emite el usuario actual al suscribirse y en cada inicio o cierre de
  /// sesión.
  Stream<UsuarioApp?> cambiosEstadoAutenticacion();

  UsuarioApp? get usuarioActual;

  Future<UsuarioApp> iniciarSesion({
    required String correo,
    required String contrasena,
  });

  /// Crea la cuenta y le asigna el nombre visible.
  Future<UsuarioApp> registrarUsuario({
    required String nombre,
    required String correo,
    required String contrasena,
  });

  Future<void> enviarCorreoRecuperacion(String correo);

  /// Envía el correo de verificación al usuario con sesión iniciada.
  Future<void> enviarCorreoVerificacion();

  /// Recarga el usuario con sesión (p. ej. para refrescar si verificó el
  /// correo).
  Future<UsuarioApp?> recargarUsuario();

  Future<void> actualizarNombreVisible(String nombre);

  Future<void> cerrarSesion();
}
