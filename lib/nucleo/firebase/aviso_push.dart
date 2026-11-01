/// `data.tipo` de una solicitud de amistad.
const String tipoAvisoSolicitudAmistad = 'solicitud_amistad';

/// Aviso que llegó por FCM o por un toque en la bandeja.
class MensajePush {
  const MensajePush({
    this.titulo,
    this.cuerpo,
    this.ruta,
    this.datos = const {},
  });

  final String? titulo;
  final String? cuerpo;
  final String? ruta;
  final Map<String, String> datos;

  /// `data.tipo` del aviso (p. ej. `solicitud_amistad`).
  String? get tipo => datos['tipo'];
}

/// Arma el mensaje desde el mapa `data` (valores de FCM, siempre texto).
MensajePush mensajeDesdeMapa({
  String? titulo,
  String? cuerpo,
  Map<String, String> datos = const {},
}) {
  final ruta = datos['ruta'];
  return MensajePush(
    titulo: titulo ?? datos['titulo'],
    cuerpo: cuerpo ?? datos['cuerpo'],
    ruta: ruta == null || ruta.isEmpty ? null : ruta,
    datos: datos,
  );
}
