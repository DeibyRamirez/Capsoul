import 'package:flutter/foundation.dart';

@immutable
class Amigo {
  const Amigo({
    required this.usuarioId,
    required this.nombreVisible,
    this.nombreUsuario,
  });

  final String usuarioId;
  final String nombreVisible;
  final String? nombreUsuario;

  String get etiquetaArroba =>
      nombreUsuario != null && nombreUsuario!.isNotEmpty
          ? '@$nombreUsuario'
          : nombreVisible;

  static Amigo? desdeFilaRpc(Map<String, dynamic> fila) {
    final id = fila['usuario_id'];
    final nombre = fila['nombre_visible'];
    if (id is! String || nombre is! String) return null;
    final arroba = fila['nombre_usuario'];
    return Amigo(
      usuarioId: id,
      nombreVisible: nombre.trim(),
      nombreUsuario: arroba is String ? arroba : null,
    );
  }
}

@immutable
class SolicitudAmistad {
  const SolicitudAmistad({
    required this.id,
    required this.solicitanteId,
    required this.solicitanteNombre,
    required this.creadoEn,
  });

  final String id;
  final String solicitanteId;
  final String solicitanteNombre;
  final DateTime creadoEn;

  static SolicitudAmistad? desdeFilaRpc(Map<String, dynamic> fila) {
    final id = fila['amistad_id'];
    final solicitante = fila['solicitante_id'];
    final nombre = fila['solicitante_nombre'];
    final creado = fila['creado_en'];
    if (id is! String || solicitante is! String || nombre is! String) {
      return null;
    }
    final creadoEn = creado is String ? DateTime.tryParse(creado) : null;
    if (creadoEn == null) return null;
    return SolicitudAmistad(
      id: id,
      solicitanteId: solicitante,
      solicitanteNombre: nombre.trim(),
      creadoEn: creadoEn,
    );
  }
}
