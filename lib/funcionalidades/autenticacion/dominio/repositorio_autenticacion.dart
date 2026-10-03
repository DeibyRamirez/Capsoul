import 'resultado_registro.dart';
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

  /// Crea la cuenta con su nombre visible. El perfil en la tabla `usuarios`
  /// lo crea el servidor (trigger `auth_usuarios_1_crear_perfil`).
  Future<ResultadoRegistro> registrarUsuario({
    required String nombre,
    required String correo,
    required String contrasena,
  });

  /// Envía el enlace de recuperación. No revela si el correo existe.
  Future<void> enviarCorreoRecuperacion(String correo);

  /// Reenvía el correo de confirmación al usuario con sesión iniciada.
  Future<void> enviarCorreoVerificacion();

  /// Recarga el usuario con sesión (p. ej. para refrescar si verificó el
  /// correo).
  Future<UsuarioApp?> recargarUsuario();

  Future<void> actualizarNombreVisible(String nombre);

  Future<void> cerrarSesion();
}
