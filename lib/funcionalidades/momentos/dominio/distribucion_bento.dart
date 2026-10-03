import 'package:flutter/foundation.dart';

import '../../elementos/dominio/tipo_elemento.dart';
import '../../recuerdos/dominio/recuerdo.dart';

/// Posición de un recuerdo en la rejilla bento de 4 columnas (en celdas).
@immutable
class CeldaBento {
  const CeldaBento({
    required this.recuerdo,
    required this.columna,
    required this.fila,
    required this.ancho,
    required this.alto,
  });

  final Recuerdo recuerdo;
  final int columna;
  final int fila;
  final int ancho;
  final int alto;

  @override
  bool operator ==(Object other) =>
      other is CeldaBento &&
      other.recuerdo.id == recuerdo.id &&
      other.columna == columna &&
      other.fila == fila &&
      other.ancho == ancho &&
      other.alto == alto;

  @override
  int get hashCode => Object.hash(recuerdo.id, columna, fila, ancho, alto);

  @override
  String toString() => 'Celda(${recuerdo.id} c$columna f$fila ${ancho}x$alto)';
}

/// Resultado de [distribuirBento]: celdas y filas totales.
typedef DistribucionBento = ({List<CeldaBento> celdas, int filas});

/// Columnas de la rejilla.
const int columnasBento = 4;

/// Reparte [recuerdos] en una rejilla de 4 columnas: cada recuerdo ocupa 2
/// columnas; las fotos y videos alternan grande (2×2) y ancho (2×1)
/// empezando por grande, las notas son 2×2 y las notas de voz 2×1. Cada
/// recuerdo va a la mitad (izquierda o derecha) que esté más arriba, así no
/// quedan huecos grandes. Función pura (sin Flutter).
DistribucionBento distribuirBento(List<Recuerdo> recuerdos) {
  final alturas = [0, 0]; // fila libre de cada mitad
  final celdas = <CeldaBento>[];
  var visuales = 0;
  for (final recuerdo in recuerdos) {
    final alto = switch (recuerdo.tipo) {
      TipoElemento.texto => 2,
      TipoElemento.audio => 1,
      TipoElemento.foto || TipoElemento.video => visuales++ % 2 == 0 ? 2 : 1,
    };
    final mitad = alturas[0] <= alturas[1] ? 0 : 1;
    celdas.add(CeldaBento(
      recuerdo: recuerdo,
      columna: mitad * 2,
      fila: alturas[mitad],
      ancho: 2,
      alto: alto,
    ));
    alturas[mitad] += alto;
  }
  final filas = alturas[0] > alturas[1] ? alturas[0] : alturas[1];
  return (celdas: celdas, filas: filas);
}
