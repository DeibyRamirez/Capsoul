import 'package:flutter/foundation.dart';

import '../../recuerdos/dominio/recuerdo.dart';
import 'estado_capsula.dart';

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
    this.destinatariosUsuarioIds = const [],
  });

  final String id;
  final String autorId;
  final String titulo;
  final String? mensaje;
  final DateTime? fechaApertura;
  final EstadoCapsula estado;
  final DateTime? liberadaEn;
  final DateTime creadoEn;

  /// Recuerdos de la cápsula, ordenados por `capsula_elementos.orden`.
  final List<Recuerdo> elementos;

  /// Destinatarios registrados (`capsula_destinatarios.usuario_id`).
  final List<String> destinatariosUsuarioIds;

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
          listEquals(other.elementos, elementos) &&
          listEquals(other.destinatariosUsuarioIds, destinatariosUsuarioIds);

  @override
  int get hashCode => Object.hash(
        id,
        autorId,
        titulo,
        mensaje,
        fechaApertura,
        estado,
        liberadaEn,
        creadoEn,
        Object.hashAll(elementos),
        Object.hashAll(destinatariosUsuarioIds),
      );

  @override
  String toString() => 'Capsula($id, $titulo, ${estado.valorBd})';
}
