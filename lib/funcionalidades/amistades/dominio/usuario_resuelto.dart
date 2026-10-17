import 'package:flutter/foundation.dart';

@immutable
class UsuarioResuelto {
  const UsuarioResuelto({
    required this.usuarioId,
    required this.nombreVisible,
  });

  final String usuarioId;
  final String nombreVisible;

  static UsuarioResuelto? desdeFilaRpc(Map<String, dynamic> fila) {
    final id = fila['usuario_id'];
    final nombre = fila['nombre_visible'];
    if (id is! String || nombre is! String) return null;
    return UsuarioResuelto(
      usuarioId: id,
      nombreVisible: nombre.trim(),
    );
  }
}
