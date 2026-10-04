import 'package:flutter/foundation.dart';

import 'enlace_medio.dart';

/// Respuesta de `firmar-medio` para un recuerdo: el original (24 h) y, en
/// fotos y videos, la miniatura (7 días), cada uno con su caducidad.
@immutable
class UrlMedio {
  const UrlMedio({
    required this.idRecuerdo,
    required this.original,
    this.publicId,
    this.miniatura,
  });

  final String idRecuerdo;

  /// `public_id` de Cloudinary (clave de las cachés).
  final String? publicId;

  /// Original (foto, video o audio).
  final EnlaceFirmado original;

  /// Miniatura de 480 px (fotos y videos).
  final EnlaceFirmado? miniatura;

  String get url => original.url;
  String? get urlMiniatura => miniatura?.url;

  /// Enlace de la [variante] o `null` si no existe.
  EnlaceFirmado? de(VarianteMedio variante) => switch (variante) {
        VarianteMedio.original => original,
        VarianteMedio.miniatura => miniatura,
      };

  /// Falla cerrado (`null`) ante una entrada incompleta o sin https. Acepta
  /// la versión 1 de la función (`expira_en` para todo).
  static UrlMedio? desdeJson(Object? datos) {
    if (datos is! Map) return null;
    final id = datos['id'];
    final publicId = datos['public_id'];
    final url = datos['url'];
    final expiraOriginal =
        _fecha(datos['expira_original']) ?? _fecha(datos['expira_en']);
    if (id is! String || !_segura(url) || expiraOriginal == null) return null;
    final miniatura = datos['url_miniatura'];
    final expiraMiniatura = _fecha(datos['expira_miniatura']) ?? expiraOriginal;
    return UrlMedio(
      idRecuerdo: id,
      publicId: publicId is String && publicId.isNotEmpty ? publicId : null,
      original: EnlaceFirmado(url: url as String, expiraEn: expiraOriginal),
      miniatura: _segura(miniatura)
          ? EnlaceFirmado(url: miniatura as String, expiraEn: expiraMiniatura)
          : null,
    );
  }

  static bool _segura(Object? url) => url is String && url.startsWith('https://');

  static DateTime? _fecha(Object? valor) =>
      valor is String ? DateTime.tryParse(valor) : null;

  @override
  bool operator ==(Object other) =>
      other is UrlMedio &&
      other.idRecuerdo == idRecuerdo &&
      other.publicId == publicId &&
      other.original == original &&
      other.miniatura == miniatura;

  @override
  int get hashCode => Object.hash(idRecuerdo, publicId, original, miniatura);
}
