import 'package:flutter/foundation.dart';

/// URLs temporales para ver el medio de un recuerdo (Edge Function
/// `firmar-medio`).
@immutable
class UrlMedio {
  const UrlMedio({
    required this.idRecuerdo,
    required this.url,
    required this.expiraEn,
    this.urlMiniatura,
  });

  final String idRecuerdo;

  /// Original (foto, video o audio); caduca en [expiraEn].
  final String url;

  /// Miniatura de 480 px (fotos y videos).
  final String? urlMiniatura;
  final DateTime expiraEn;

  /// `true` si sigue sirviendo al menos [margen] más.
  bool vigente(DateTime ahora, {Duration margen = const Duration(minutes: 5)}) =>
      expiraEn.isAfter(ahora.add(margen));

  /// Falla cerrado (`null`) ante una entrada incompleta o sin https.
  static UrlMedio? desdeJson(Object? datos) {
    if (datos is! Map) return null;
    final id = datos['id'];
    final url = datos['url'];
    final miniatura = datos['url_miniatura'];
    final expira = datos['expira_en'];
    final expiraEn = expira is String ? DateTime.tryParse(expira) : null;
    if (id is! String ||
        url is! String ||
        !url.startsWith('https://') ||
        expiraEn == null) {
      return null;
    }
    return UrlMedio(
      idRecuerdo: id,
      url: url,
      urlMiniatura:
          miniatura is String && miniatura.startsWith('https://') ? miniatura : null,
      expiraEn: expiraEn,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is UrlMedio &&
      other.idRecuerdo == idRecuerdo &&
      other.url == url &&
      other.urlMiniatura == urlMiniatura &&
      other.expiraEn == expiraEn;

  @override
  int get hashCode => Object.hash(idRecuerdo, url, urlMiniatura, expiraEn);
}
