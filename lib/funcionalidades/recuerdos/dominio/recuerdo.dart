import 'package:flutter/foundation.dart';

import '../../elementos/dominio/tipo_elemento.dart';

/// Recuerdo del banco de recuerdos: una fila de `elementos` (foto, video,
/// nota de voz o nota) que existe por sí sola y se puede agregar a cápsulas
/// y momentos.
@immutable
class Recuerdo {
  const Recuerdo({
    required this.id,
    required this.propietarioId,
    required this.tipo,
    required this.fechaRecuerdo,
    required this.creadoEn,
    this.titulo,
    this.contenidoTexto,
    this.publicId,
    this.formato,
    this.bytes,
    this.ancho,
    this.alto,
    this.duracion,
  });

  final String id;
  final String propietarioId;
  final TipoElemento tipo;

  /// Día del recuerdo (sin hora), para agrupar y filtrar.
  final DateTime fechaRecuerdo;
  final DateTime creadoEn;
  final String? titulo;
  final String? contenidoTexto;

  /// `public_id` de Cloudinary (`null` en las notas).
  final String? publicId;
  final String? formato;
  final int? bytes;
  final int? ancho;
  final int? alto;
  final Duration? duracion;

  static const int _caracteresNombreNota = 40;

  /// Foto o video: tiene imagen (miniatura) y puede ser portada.
  bool get esVisual => tipo == TipoElemento.foto || tipo == TipoElemento.video;

  /// Nombre para mostrar: el título o, si no hay, uno según el tipo.
  String get nombre {
    final propio = titulo?.trim();
    if (propio != null && propio.isNotEmpty) return propio;
    if (tipo == TipoElemento.texto) {
      final primeraLinea = (contenidoTexto ?? '').trim().split('\n').first;
      if (primeraLinea.isEmpty) return tipo.etiqueta;
      final runas = primeraLinea.runes.toList();
      return runas.length <= _caracteresNombreNota
          ? primeraLinea
          : '${String.fromCharCodes(runas.take(_caracteresNombreNota))}…';
    }
    return tipo.etiqueta;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Recuerdo &&
          other.id == id &&
          other.propietarioId == propietarioId &&
          other.tipo == tipo &&
          other.fechaRecuerdo == fechaRecuerdo &&
          other.creadoEn == creadoEn &&
          other.titulo == titulo &&
          other.contenidoTexto == contenidoTexto &&
          other.publicId == publicId &&
          other.formato == formato &&
          other.bytes == bytes &&
          other.ancho == ancho &&
          other.alto == alto &&
          other.duracion == duracion;

  @override
  int get hashCode => Object.hash(id, propietarioId, tipo, fechaRecuerdo,
      creadoEn, titulo, contenidoTexto, publicId, formato, bytes, ancho, alto,
      duracion);

  @override
  String toString() => 'Recuerdo($id, ${tipo.valorBd})';
}
