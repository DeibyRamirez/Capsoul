/// Respuesta de Cloudinary tras una subida firmada; es lo que se guarda en
/// la tabla `elementos` (nunca el archivo).
class MedioSubido {
  const MedioSubido({
    required this.publicId,
    required this.tipoRecurso,
    required this.bytes,
    this.version,
    this.formato,
    this.ancho,
    this.alto,
    this.duracionSegundos,
  });

  final String publicId;

  /// `image` o `video` (el audio es `video` en Cloudinary).
  final String tipoRecurso;
  final int bytes;
  final int? version;
  final String? formato;
  final int? ancho;
  final int? alto;
  final double? duracionSegundos;
}
