import 'package:flutter/foundation.dart';

import '../../recuerdos/dominio/recuerdo.dart';

/// Datos que el usuario llena al crear una cápsula. Los recuerdos ya están
/// guardados en el banco de recuerdos.
@immutable
class NuevaCapsula {
  const NuevaCapsula({
    required this.titulo,
    required this.fechaApertura,
    required this.recuerdos,
    required this.destinatariosUsuarioIds,
    this.mensaje,
    this.imagenClave,
  });

  final String titulo;
  final String? mensaje;
  final DateTime fechaApertura;
  final List<Recuerdo> recuerdos;

  /// Amigos aceptados que recibirán la cápsula (`capsula_destinatarios.usuario_id`).
  final List<String> destinatariosUsuarioIds;

  /// Clave de la imagen local elegida (`capsulas.imagen_clave`).
  final String? imagenClave;
}
