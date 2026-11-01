import 'package:flutter/foundation.dart';

import 'referencia_musica.dart';

/// Pista tal como la devuelve la API publica de Deezer
/// (`/search` y `/track/<id>`). Inmutable.
@immutable
class PistaDeezer {
  const PistaDeezer({
    required this.id,
    required this.titulo,
    required this.artista,
    required this.enlace,
    this.album,
    this.portadaUrl,
    this.previewUrl,
    this.duracionSegundos,
  });

  /// Lee el JSON de una pista. Lanza [FormatException] si faltan
  /// id, titulo o artista.
  factory PistaDeezer.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final titulo = _texto(json['title']);
    final artistaJson = json['artist'];
    final artista =
        artistaJson is Map ? _texto(artistaJson['name']) : null;
    if (id is! num || titulo == null || artista == null) {
      throw const FormatException('Pista de Deezer incompleta');
    }
    final idTexto = id.toInt().toString();
    final albumJson = json['album'];
    String? album;
    String? portada;
    if (albumJson is Map) {
      album = _texto(albumJson['title']);
      portada = _texto(albumJson['cover_medium']) ??
          _texto(albumJson['cover_big']) ??
          _texto(albumJson['cover']);
    }
    final duracion = json['duration'];
    return PistaDeezer(
      id: idTexto,
      titulo: titulo,
      artista: artista,
      album: album,
      portadaUrl: portada,
      previewUrl: _texto(json['preview']),
      enlace: _texto(json['link']) ?? 'https://www.deezer.com/track/$idTexto',
      duracionSegundos: duracion is num ? duracion.toInt() : null,
    );
  }

  /// Version tolerante: null si el JSON no es una pista valida.
  static PistaDeezer? intentarDesdeJson(Object? json) {
    if (json is! Map) return null;
    try {
      return PistaDeezer.fromJson(Map<String, dynamic>.from(json));
    } on FormatException {
      return null;
    }
  }

  final String id;
  final String titulo;
  final String artista;
  final String? album;
  final String? portadaUrl;

  /// URL del clip de 30 s. Caduca: no se guarda en la base de datos.
  final String? previewUrl;
  final String enlace;
  final int? duracionSegundos;

  bool get tienePreview => previewUrl != null && previewUrl!.isNotEmpty;

  /// Convierte a la referencia que usa el resto de la app.
  ReferenciaMusica aReferencia() => ReferenciaMusica(
        proveedor: ProveedorMusica.deezer,
        idExterno: id,
        titulo: titulo,
        artista: artista,
        urlCompleta: enlace,
        enlaceDeezer: enlace,
        previewUrl: previewUrl,
        previewProveedor: tienePreview ? ProveedorPreviewMusica.deezer : null,
        portadaUrl: portadaUrl,
        uriProfundo: enlaceProfundoDeezer(id).toString(),
      );

  static String? _texto(Object? valor) =>
      valor is String && valor.trim().isNotEmpty ? valor.trim() : null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PistaDeezer &&
          other.id == id &&
          other.titulo == titulo &&
          other.artista == artista &&
          other.album == album &&
          other.portadaUrl == portadaUrl &&
          other.previewUrl == previewUrl &&
          other.enlace == enlace &&
          other.duracionSegundos == duracionSegundos;

  @override
  int get hashCode => Object.hash(
        id,
        titulo,
        artista,
        album,
        portadaUrl,
        previewUrl,
        enlace,
        duracionSegundos,
      );
}

/// Deep link de la app de Deezer para una pista.
Uri enlaceProfundoDeezer(String idPista) =>
    Uri.parse('deezer://www.deezer.com/track/$idPista');
