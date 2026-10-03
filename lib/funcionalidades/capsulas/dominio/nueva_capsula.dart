import 'package:flutter/foundation.dart';

import '../../elementos/dominio/elemento_borrador.dart';

/// Datos que el usuario llena al crear una cápsula.
@immutable
class NuevaCapsula {
  const NuevaCapsula({
    required this.titulo,
    required this.fechaApertura,
    required this.elementos,
    this.mensaje,
  });

  final String titulo;
  final String? mensaje;
  final DateTime fechaApertura;
  final List<ElementoBorrador> elementos;
}
