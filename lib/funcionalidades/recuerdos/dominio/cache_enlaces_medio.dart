import 'enlace_medio.dart';
import 'url_medio.dart';

/// Enlaces firmados vigentes en memoria, por `public_id` y variante. Se
/// reutilizan hasta [margen] antes de caducar; después hay que volver a
/// pedirlos a `firmar-medio`.
class CacheEnlacesMedio {
  CacheEnlacesMedio({
    DateTime Function()? reloj,
    this.margen = EnlaceFirmado.margenRenovacion,
  }) : _reloj = reloj ?? DateTime.now;

  final DateTime Function() _reloj;
  final Duration margen;
  final Map<String, EnlaceFirmado> _enlaces = {};

  int get cantidad => _enlaces.length;

  /// Enlace vigente o `null` (si falta o está por vencer, y entonces se quita).
  EnlaceFirmado? vigente(String publicId, VarianteMedio variante) {
    final clave = claveMedio(publicId, variante);
    final enlace = _enlaces[clave];
    if (enlace == null) return null;
    if (enlace.vigente(_reloj(), margen: margen)) return enlace;
    _enlaces.remove(clave);
    return null;
  }

  void guardar(String publicId, VarianteMedio variante, EnlaceFirmado enlace) {
    _enlaces[claveMedio(publicId, variante)] = enlace;
  }

  /// Guarda las variantes de [medio] bajo [publicId].
  void guardarMedio(String publicId, UrlMedio medio) {
    for (final variante in VarianteMedio.values) {
      final enlace = medio.de(variante);
      if (enlace != null) guardar(publicId, variante, enlace);
    }
  }

  /// Quita los enlaces vencidos o por vencer.
  void limpiarVencidos() {
    final ahora = _reloj();
    _enlaces.removeWhere((_, enlace) => !enlace.vigente(ahora, margen: margen));
  }

  void vaciar() => _enlaces.clear();
}
