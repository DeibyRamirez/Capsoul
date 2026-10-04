import 'package:flutter/foundation.dart';

import '../../recuerdos/dominio/recuerdo.dart';

/// Momento: un grupo de recuerdos con nombre, descripción y portada (tabla
/// `momentos` + `momento_elementos`).
@immutable
class Momento {
  const Momento({
    required this.id,
    required this.autorId,
    required this.titulo,
    required this.creadoEn,
    this.descripcion,
    this.portada,
    this.cantidad = 0,
    this.recuerdos = const [],
  });

  final String id;
  final String autorId;
  final String titulo;
  final String? descripcion;
  final DateTime creadoEn;

  /// Foto o video elegido como portada (`null` si no hay).
  final Recuerdo? portada;

  /// Cuántos recuerdos tiene (en el listado no se traen todos).
  final int cantidad;

  /// Recuerdos ordenados (solo en el detalle).
  final List<Recuerdo> recuerdos;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Momento &&
          other.id == id &&
          other.autorId == autorId &&
          other.titulo == titulo &&
          other.descripcion == descripcion &&
          other.creadoEn == creadoEn &&
          other.portada == portada &&
          other.cantidad == cantidad &&
          listEquals(other.recuerdos, recuerdos);

  @override
  int get hashCode => Object.hash(id, autorId, titulo, descripcion, creadoEn,
      portada, cantidad, Object.hashAll(recuerdos));

  @override
  String toString() => 'Momento($id, $titulo)';
}
