import 'package:flutter/foundation.dart';

/// Metadatos de una pista de catálogo (Deezer; filas antiguas de Spotify).
@immutable
class ReferenciaMusica {
  const ReferenciaMusica({
    required this.idExterno,
    required this.titulo,
    required this.artista,
    required this.urlCompleta,
    this.previewUrl,
    this.previewProveedor,
    this.portadaUrl,
    this.uriProfundo,
    this.enlaceDeezer,
    this.proveedor = ProveedorMusica.spotify,
  });

  final ProveedorMusica proveedor;
  final String idExterno;
  final String titulo;
  final String artista;

  /// Clip de 30 s. En Deezer caduca: no se guarda y se vuelve a pedir.
  final String? previewUrl;

  /// Origen del clip de 30 s (`spotify`, `deezer` o null si no hay preview).
  final ProveedorPreviewMusica? previewProveedor;
  final String urlCompleta;
  final String? portadaUrl;
  final String? uriProfundo;

  /// URL de la pista en Deezer.
  final String? enlaceDeezer;

  String get etiquetaCorta => '$artista — $titulo';

  bool get tienePreview =>
      previewUrl != null && previewUrl!.trim().isNotEmpty;

  bool get esDeezer => proveedor == ProveedorMusica.deezer;

  /// Una pista de Deezer guardada no trae preview (caduca), pero se puede
  /// pedir de nuevo por id antes de reproducir.
  bool get puedeReproducirPreview => tienePreview || idPistaDeezer != null;

  /// Id numérico de la pista en Deezer, si se conoce.
  String? get idPistaDeezer {
    if (esDeezer) return idExterno;
    final enlace = enlaceDeezer;
    if (enlace == null) return null;
    return RegExp(r'/track/(\d+)').firstMatch(enlace)?.group(1);
  }

  /// Consulta de texto para buscar la pista en otras plataformas.
  String get consultaBusqueda => '$artista $titulo'.trim();

  ReferenciaMusica copiarConPreview({
    required String? previewUrl,
    ProveedorPreviewMusica? previewProveedor,
    String? portadaUrl,
    String? enlaceDeezer,
  }) =>
      ReferenciaMusica(
        proveedor: proveedor,
        idExterno: idExterno,
        titulo: titulo,
        artista: artista,
        urlCompleta: urlCompleta,
        previewUrl: previewUrl,
        previewProveedor: previewProveedor ?? this.previewProveedor,
        portadaUrl: portadaUrl ?? this.portadaUrl,
        uriProfundo: uriProfundo,
        enlaceDeezer: enlaceDeezer ?? this.enlaceDeezer,
      );

  static ReferenciaMusica? desdeJsonApi(Object? datos) {
    if (datos is! Map) return null;
    final id = datos['idExterno'];
    final titulo = datos['titulo'];
    final artista = datos['artista'];
    final url = datos['urlCompleta'];
    if (id is! String ||
        titulo is! String ||
        artista is! String ||
        url is! String) {
      return null;
    }
    return ReferenciaMusica(
      idExterno: id,
      titulo: titulo.trim(),
      artista: artista.trim(),
      urlCompleta: url.trim(),
      previewUrl: _texto(datos['previewUrl']),
      previewProveedor: ProveedorPreviewMusica.desdeApi(datos['previewProveedor']),
      portadaUrl: _texto(datos['portadaUrl']),
      uriProfundo: _texto(datos['uriProfundo']),
      enlaceDeezer: _texto(datos['enlaceDeezer']),
    );
  }

  ProveedorPreviewMusica? get previewProveedorEfectivo {
    if (previewProveedor != null) return previewProveedor;
    if (esDeezer) return ProveedorPreviewMusica.deezer;
    final url = previewUrl?.toLowerCase() ?? '';
    if (url.contains('dzcdn') || url.contains('deezer')) {
      return ProveedorPreviewMusica.deezer;
    }
    return null;
  }

  String get etiquetaPreview {
    if (esDeezer) {
      return tienePreview ? 'Vista previa de 30 s' : 'Sin vista previa';
    }
    return switch (previewProveedorEfectivo) {
      ProveedorPreviewMusica.deezer => 'Vista previa (Deezer)',
      ProveedorPreviewMusica.spotify => 'Vista previa',
      null => tienePreview ? 'Vista previa' : 'Solo en Spotify',
    };
  }

  static ReferenciaMusica? desdeFilaBd(Map<dynamic, dynamic> datos) {
    final id = datos['musica_id_externo'];
    final titulo = datos['musica_titulo'];
    final artista = datos['musica_artista'];
    final url = datos['musica_url_completa'];
    if (id is! String ||
        titulo is! String ||
        artista is! String ||
        url is! String) {
      return null;
    }
    final proveedor = ProveedorMusica.desdeValorBd(datos['musica_proveedor']) ??
        ProveedorMusica.spotify;
    final previewUrl = _texto(datos['musica_preview_url']);
    final previewProv = ProveedorPreviewMusica.desdeApi(
      datos['musica_preview_proveedor'],
    );
    return ReferenciaMusica(
      proveedor: proveedor,
      idExterno: id,
      titulo: titulo,
      artista: artista,
      urlCompleta: url,
      previewUrl: previewUrl,
      previewProveedor: previewProv,
      portadaUrl: _texto(datos['musica_portada_url']),
      uriProfundo: _texto(datos['musica_uri_profundo']),
      enlaceDeezer: _texto(datos['musica_enlace_deezer']),
    );
  }

  /// Solo metadatos. En Deezer nunca se guarda la URL del preview (caduca).
  Map<String, dynamic> aFilaBd() => {
        'musica_proveedor': proveedor.valorBd,
        'musica_id_externo': idExterno,
        'musica_titulo': titulo,
        'musica_artista': artista,
        'musica_preview_url': esDeezer ? null : previewUrl,
        if (previewProveedor != null || esDeezer)
          'musica_preview_proveedor':
              (previewProveedor ?? ProveedorPreviewMusica.deezer).valorApi,
        'musica_url_completa': urlCompleta,
        'musica_portada_url': portadaUrl,
        'musica_uri_profundo': uriProfundo,
        'musica_enlace_deezer': enlaceDeezer,
      };

  static String? _texto(Object? valor) =>
      valor is String && valor.trim().isNotEmpty ? valor.trim() : null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReferenciaMusica &&
          other.proveedor == proveedor &&
          other.idExterno == idExterno &&
          other.titulo == titulo &&
          other.artista == artista &&
          other.previewUrl == previewUrl &&
          other.previewProveedor == previewProveedor &&
          other.urlCompleta == urlCompleta &&
          other.portadaUrl == portadaUrl &&
          other.uriProfundo == uriProfundo &&
          other.enlaceDeezer == enlaceDeezer;

  @override
  int get hashCode => Object.hash(
        proveedor,
        idExterno,
        titulo,
        artista,
        previewUrl,
        previewProveedor,
        urlCompleta,
        portadaUrl,
        uriProfundo,
        enlaceDeezer,
      );
}

enum ProveedorMusica {
  spotify('spotify'),
  deezer('deezer');

  const ProveedorMusica(this.valorBd);
  final String valorBd;

  static ProveedorMusica? desdeValorBd(Object? valor) {
    for (final p in ProveedorMusica.values) {
      if (p.valorBd == valor) return p;
    }
    return null;
  }
}

enum ProveedorPreviewMusica {
  spotify('spotify'),
  deezer('deezer');

  const ProveedorPreviewMusica(this.valorApi);
  final String valorApi;

  static ProveedorPreviewMusica? desdeApi(Object? valor) {
    if (valor is! String) return null;
    for (final p in ProveedorPreviewMusica.values) {
      if (p.valorApi == valor) return p;
    }
    return null;
  }
}
