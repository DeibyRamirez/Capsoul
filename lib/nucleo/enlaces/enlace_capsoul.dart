/// Construcción de deep links de la app (fase 1: esquema `capsoul://`).
abstract final class EnlaceCapsoul {
  static const String esquema = 'capsoul';

  static String capsula(String idCapsula) =>
      '$esquema://capsula/${Uri.encodeComponent(idCapsula)}';

  static String amistad(String token) =>
      '$esquema://amistad/${Uri.encodeComponent(token)}';

  static String herencia(String id) =>
      '$esquema://herencia/${Uri.encodeComponent(id)}';

  static String reto(String id) => '$esquema://reto/${Uri.encodeComponent(id)}';

  static String amigos() => '$esquema://amigos';

  static String? idCapsulaDesde(Uri uri) => _segmento(uri, 'capsula');

  static String? tokenAmistadDesde(Uri uri) => _segmento(uri, 'amistad');

  static String? idHerenciaDesde(Uri uri) => _segmento(uri, 'herencia');

  static String? idRetoDesde(Uri uri) => _segmento(uri, 'reto');

  static bool esAmigos(Uri uri) => uri.scheme == esquema && uri.host == 'amigos';

  static String? _segmento(Uri uri, String host) {
    if (uri.scheme != esquema || uri.host != host) return null;
    if (uri.pathSegments.isNotEmpty) {
      return Uri.decodeComponent(uri.pathSegments.first);
    }
    if (uri.path.length > 1) {
      return Uri.decodeComponent(uri.path.substring(1));
    }
    return null;
  }
}
