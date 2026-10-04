import 'package:flutter/foundation.dart';

/// Conteos de las tarjetas de Inicio. Un conteo que no se pudo leer vale 0.
@immutable
class ResumenInicio {
  const ResumenInicio({
    this.recuerdos = 0,
    this.retosActivos = 0,
    this.capsulas = 0,
    this.herencias = 0,
  });

  static const ResumenInicio vacio = ResumenInicio();

  /// Momentos guardados por el usuario.
  final int recuerdos;

  /// Retos aceptados en los que participa.
  final int retosActivos;

  /// Cápsulas creadas (sin canceladas).
  final int capsulas;

  /// Herencias creadas (sin revocadas).
  final int herencias;

  @override
  bool operator ==(Object other) =>
      other is ResumenInicio &&
      other.recuerdos == recuerdos &&
      other.retosActivos == retosActivos &&
      other.capsulas == capsulas &&
      other.herencias == herencias;

  @override
  int get hashCode => Object.hash(recuerdos, retosActivos, capsulas, herencias);
}
