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
    this.mensaje,
  });

  final String titulo;
  final String? mensaje;
  final DateTime fechaApertura;
  final List<Recuerdo> recuerdos;
}
