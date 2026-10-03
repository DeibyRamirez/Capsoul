import '../../../nucleo/errores/fallo_app.dart';

/// Fallo al leer o escribir la tabla `usuarios`, con mensaje en español.
class FalloPerfilUsuario implements FalloApp {
  const FalloPerfilUsuario._(this.codigo, this.mensaje);

  factory FalloPerfilUsuario.desdeCodigo(String codigo) {
    final mensaje = switch (codigo) {
      codigoPermisoDenegado =>
        'No tienes permiso para ver o editar este perfil.',
      codigoSinRed => 'Sin conexión. Revisa tu internet e inténtalo de nuevo.',
      codigoNoEncontrado => 'No encontramos tu perfil.',
      codigoDatoInvalido => 'El nombre debe tener entre 1 y 60 caracteres.',
      _ => kMensajeErrorInesperado,
    };
    return FalloPerfilUsuario._(codigo, mensaje);
  }

  static const String codigoPermisoDenegado = 'permiso_denegado';
  static const String codigoSinRed = 'sin_red';
  static const String codigoNoEncontrado = 'no_encontrado';
  static const String codigoDatoInvalido = 'dato_invalido';

  /// Código usado cuando el error no se reconoce.
  static const String codigoDesconocido = 'desconocido';

  @override
  final String codigo;

  @override
  final String mensaje;

  @override
  String toString() => 'FalloPerfilUsuario($codigo): $mensaje';
}
