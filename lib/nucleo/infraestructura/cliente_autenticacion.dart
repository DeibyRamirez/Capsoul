import '../../funcionalidades/autenticacion/dominio/resultado_registro.dart';
import '../../funcionalidades/autenticacion/dominio/usuario_app.dart';

/// Evento de cambio de sesión.
enum EventoAutenticacion {
  iniciada,
  cerrada,
  recuperacionContrasena,
  actualizada,
  desconocido,
}

/// Datos de sesión del proveedor de autenticación.
class SesionAutenticacion {
  const SesionAutenticacion({
    required this.usuario,
    required this.evento,
  });

  final UsuarioApp? usuario;
  final EventoAutenticacion evento;
}

/// Error de autenticación independiente del SDK.
class ExcepcionAutenticacion implements Exception {
  const ExcepcionAutenticacion({this.codigo, required this.mensaje});

  final String? codigo;
  final String mensaje;

  @override
  String toString() => 'ExcepcionAutenticacion($codigo): $mensaje';
}

/// Contrato de autenticación independiente de Supabase Auth.
abstract interface class ClienteAutenticacion {
  Stream<SesionAutenticacion> cambiosEstado();

  UsuarioApp? get usuarioActual;

  String? get tokenAcceso;

  Future<UsuarioApp> iniciarSesion({
    required String correo,
    required String contrasena,
  });

  Future<ResultadoRegistro> registrarUsuario({
    required String nombre,
    required String correo,
    required String contrasena,
    required String urlConfirmacion,
  });

  Future<void> enviarCorreoRecuperacion(
    String correo, {
    required String urlRecuperacion,
  });

  Future<void> reenviarCorreoConfirmacion(
    String correo, {
    required String urlConfirmacion,
  });

  Future<void> actualizarContrasena(String contrasenaNueva);

  Future<void> actualizarNombreVisible(String nombre);

  Future<void> cerrarSesion();
}
