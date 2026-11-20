import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../elementos/dominio/nota_serializada.dart';
import '../../elementos/dominio/tipo_elemento.dart';
import '../../musica/dominio/referencia_musica.dart';

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
    this.contenidoRico,
    this.publicId,
    this.formato,
    this.bytes,
    this.ancho,
    this.alto,
    this.duracion,
    this.musica,
  });

  final String id;
  final String propietarioId;
  final TipoElemento tipo;

  /// Día del recuerdo (sin hora), para agrupar y filtrar.
  final DateTime fechaRecuerdo;
  final DateTime creadoEn;
  final String? titulo;
  final String? contenidoTexto;

  /// Delta JSON de una nota enriquecida (`null` en notas legacy y medios).
  final Object? contenidoRico;

  /// Nota parseada desde `contenido_texto` + `contenido_rico`.
  NotaSerializada get nota => NotaSerializada.desdeColumnas(
    contenidoTexto: contenidoTexto,
    contenidoRico: contenidoRico,
  );

  /// `public_id` de Cloudinary (`null` en las notas).
  final String? publicId;
  final String? formato;
  final int? bytes;
  final int? ancho;
  final int? alto;
  final Duration? duracion;

  /// Catálogo Spotify: elemento `musica` o adjunto a una foto.
  final ReferenciaMusica? musica;

  static const int _caracteresNombreNota = 40;

  bool get tieneMusica => musica != null;

  /// Foto o video: tiene imagen (miniatura) y puede ser portada.
  bool get esVisual => tipo == TipoElemento.foto || tipo == TipoElemento.video;

  /// Nombre para mostrar: el título o, si no hay, uno según el tipo.
  String get nombre {
    final propio = titulo?.trim();
    if (propio != null && propio.isNotEmpty) return propio;
    if (tipo == TipoElemento.musica && musica != null) {
      return musica!.etiquetaCorta;
    }
    if (tipo == TipoElemento.texto) {
      final cuerpo = nota.cuerpo;
      final primeraLinea = NotaSerializada.markdownAPlano(cuerpo)
          .trim()
          .split('\n')
          .first;
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
          _ricoCanonico(other.contenidoRico) == _ricoCanonico(contenidoRico) &&
          other.publicId == publicId &&
          other.formato == formato &&
          other.bytes == bytes &&
          other.ancho == ancho &&
          other.alto == alto &&
          other.duracion == duracion &&
          other.musica == musica;

  static String? _ricoCanonico(Object? valor) {
    if (valor == null) return null;
    try {
      return jsonEncode(_ordenarJson(valor));
    } catch (_) {
      return valor.toString();
    }
  }

  static Object? _ordenarJson(Object? valor) {
    if (valor is Map) {
      final claves = valor.keys.map((clave) => clave.toString()).toList()
        ..sort();
      return {for (final clave in claves) clave: _ordenarJson(valor[clave])};
    }
    if (valor is List) return [for (final item in valor) _ordenarJson(item)];
    return valor;
  }

  @override
  int get hashCode => Object.hash(
    id,
    propietarioId,
    tipo,
    fechaRecuerdo,
    creadoEn,
    titulo,
    contenidoTexto,
    _ricoCanonico(contenidoRico),
    publicId,
    formato,
    bytes,
    ancho,
    alto,
    duracion,
    musica,
  );

  @override
  String toString() => 'Recuerdo($id, ${tipo.valorBd})';
}
