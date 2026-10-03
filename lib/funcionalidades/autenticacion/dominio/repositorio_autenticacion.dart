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

  /// Reenvía el correo de confirmación de registro a [correo]. No requiere
  /// sesión: la cuenta aún no está confirmada.
  Future<void> reenviarCorreoConfirmacion(String correo);

  /// Emite cada vez que se abre un enlace de recuperación de contraseña
  /// (evento `passwordRecovery`): hay sesión temporal y falta la contraseña
  /// nueva.
  Stream<void> enlacesRecuperacion();

  /// Cambia la contraseña del usuario con sesión (tras el enlace de
  /// recuperación).
  Future<void> actualizarContrasena(String contrasenaNueva);

  Future<void> actualizarNombreVisible(String nombre);

  Future<void> cerrarSesion();
}
