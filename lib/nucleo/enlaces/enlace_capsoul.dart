/// Construcción de deep links de la app (fase 1: esquema `capsoul://`).
abstract final class EnlaceCapsoul {
  static const String esquema = 'capsoul';

  static String capsula(String idCapsula) =>
      '$esquema://capsula/${Uri.encodeComponent(idCapsula)}';

  static String amistad(String token) =>
      '$esquema://amistad/${Uri.encodeComponent(token)}';

  static String? idCapsulaDesde(Uri uri) {
    if (uri.scheme != esquema) return null;
    if (uri.host != 'capsula') return null;
    if (uri.pathSegments.isNotEmpty) {
      return Uri.decodeComponent(uri.pathSegments.first);
    }
    if (uri.path.length > 1) {
      return Uri.decodeComponent(uri.path.substring(1));
    }
    return null;
  }

  static String? tokenAmistadDesde(Uri uri) {
    if (uri.scheme != esquema) return null;
    if (uri.host != 'amistad') return null;
    if (uri.pathSegments.isNotEmpty) {
      return Uri.decodeComponent(uri.pathSegments.first);
    }
    if (uri.path.length > 1) {
      return Uri.decodeComponent(uri.path.substring(1));
    }
    return null;
  }
}
