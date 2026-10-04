import 'package:flutter/foundation.dart';

import '../../recuerdos/dominio/recuerdo.dart';

/// Datos que el usuario llena al crear un momento.
@immutable
class NuevoMomento {
  const NuevoMomento({
    required this.titulo,
    required this.recuerdos,
    this.descripcion,
    this.portadaId,
  });

  final String titulo;
  final String? descripcion;
  final List<Recuerdo> recuerdos;

  /// Id del recuerdo de portada (foto o video de [recuerdos]).
  final String? portadaId;
}
