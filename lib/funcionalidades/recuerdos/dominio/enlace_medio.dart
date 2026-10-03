import 'package:flutter/foundation.dart';

/// Variante de un medio de Cloudinary: la miniatura de 480 px (listas y
/// rejillas) o el original (solo en el detalle).
enum VarianteMedio { miniatura, original }

/// Clave estable de un medio en las cachés del dispositivo: el `public_id` y
/// la variante, nunca la URL firmada (cambia en cada firma).
String claveMedio(String publicId, VarianteMedio variante) =>
    '$publicId|${variante.name}';

/// URL firmada de `firmar-medio` con su caducidad.
@immutable
class EnlaceFirmado {
  const EnlaceFirmado({required this.url, required this.expiraEn});

  final String url;
  final DateTime expiraEn;

  /// Margen antes de caducar a partir del cual se vuelve a pedir la firma.
  static const Duration margenRenovacion = Duration(minutes: 5);

  /// `true` si sigue sirviendo al menos [margen] más.
  bool vigente(DateTime ahora, {Duration margen = margenRenovacion}) =>
      expiraEn.isAfter(ahora.add(margen));

  @override
  bool operator ==(Object other) =>
      other is EnlaceFirmado && other.url == url && other.expiraEn == expiraEn;

  @override
  int get hashCode => Object.hash(url, expiraEn);
}
