import 'package:flutter/foundation.dart';

import '../../elementos/dominio/tipo_elemento.dart';
import 'estado_capsula.dart';

/// Elemento ya guardado y unido a una cápsula (fila de `elementos` +
/// `capsula_elementos.orden`).
@immutable
class ElementoCapsula {
  const ElementoCapsula({
    required this.id,
    required this.tipo,
    this.orden = 0,
    this.contenidoTexto,
    this.publicId,
    this.bytes,
    this.duracion,
  });

  final String id;
  final TipoElemento tipo;
  final int orden;
  final String? contenidoTexto;
  final String? publicId;
  final int? bytes;
  final Duration? duracion;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ElementoCapsula &&
          other.id == id &&
          other.tipo == tipo &&
          other.orden == orden &&
          other.contenidoTexto == contenidoTexto &&
          other.publicId == publicId &&
          other.bytes == bytes &&
          other.duracion == duracion;

  @override
  int get hashCode =>
      Object.hash(id, tipo, orden, contenidoTexto, publicId, bytes, duracion);
}

/// Cápsula del tiempo (tabla `capsulas`).
@immutable
class Capsula {
  const Capsula({
    required this.id,
    required this.autorId,
    required this.titulo,
    required this.estado,
    required this.creadoEn,
    this.mensaje,
    this.fechaApertura,
    this.liberadaEn,
    this.elementos = const [],
  });

  final String id;
  final String autorId;
  final String titulo;
  final String? mensaje;
  final DateTime? fechaApertura;
  final EstadoCapsula estado;
  final DateTime? liberadaEn;
  final DateTime creadoEn;

  /// Ordenados por `orden`.
  final List<ElementoCapsula> elementos;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Capsula &&
          other.id == id &&
          other.autorId == autorId &&
          other.titulo == titulo &&
          other.mensaje == mensaje &&
          other.fechaApertura == fechaApertura &&
          other.estado == estado &&
          other.liberadaEn == liberadaEn &&
          other.creadoEn == creadoEn &&
          listEquals(other.elementos, elementos);

  @override
  int get hashCode => Object.hash(id, autorId, titulo, mensaje, fechaApertura,
      estado, liberadaEn, creadoEn, Object.hashAll(elementos));

  @override
  String toString() => 'Capsula($id, $titulo, ${estado.valorBd})';
}
