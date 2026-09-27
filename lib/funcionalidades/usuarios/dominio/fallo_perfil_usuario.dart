import '../../../nucleo/errores/fallo_app.dart';

/// Fallo al leer o escribir `usuarios/{uid}`, con mensaje en español.
class FalloPerfilUsuario implements FalloApp {
  const FalloPerfilUsuario._(this.codigo, this.mensaje);

  factory FalloPerfilUsuario.desdeCodigo(String codigo) {
    final mensaje = switch (codigo) {
      'permission-denied' => 'No tienes permiso para ver o editar este perfil.',
      'unavailable' => 'Sin conexión. Revisa tu internet e inténtalo de nuevo.',
      'not-found' => 'No encontramos tu perfil.',
      _ => kMensajeErrorInesperado,
    };
    return FalloPerfilUsuario._(codigo, mensaje);
  }

  /// Código usado cuando el error no viene de Firebase.
  static const String codigoDesconocido = 'desconocido';

  @override
  final String codigo;

  @override
  final String mensaje;

  @override
  String toString() => 'FalloPerfilUsuario($codigo): $mensaje';
}
