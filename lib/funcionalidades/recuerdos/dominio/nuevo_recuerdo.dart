import 'package:flutter/foundation.dart';

import '../../elementos/dominio/elemento_borrador.dart';

/// Datos para guardar un recuerdo recién capturado.
@immutable
class NuevoRecuerdo {
  const NuevoRecuerdo({
    required this.elemento,
    required this.fechaRecuerdo,
    this.titulo,
  });

  final ElementoBorrador elemento;
  final DateTime fechaRecuerdo;
  final String? titulo;
}
