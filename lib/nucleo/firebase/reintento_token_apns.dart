/// Esperas entre intentos de leer el token APNs en iOS (≈ 1 minuto en total).
const List<Duration> esperasTokenApns = [
  Duration(seconds: 1),
  Duration(seconds: 2),
  Duration(seconds: 4),
  Duration(seconds: 8),
  Duration(seconds: 15),
  Duration(seconds: 30),
];

/// Llama a [leer] hasta que devuelva un texto no vacío, esperando entre
/// intentos según [esperas]. Devuelve null si nunca llega (luego llegará por
/// `onTokenRefresh`). Los errores de [leer] cuentan como intento fallido.
Future<String?> esperarConReintentos(
  Future<String?> Function() leer, {
  List<Duration> esperas = esperasTokenApns,
  Future<void> Function(Duration espera)? dormir,
}) async {
  final pausa = dormir ?? (espera) => Future<void>.delayed(espera);
  for (var intento = 0; intento <= esperas.length; intento++) {
    try {
      final valor = await leer();
      if (valor != null && valor.isNotEmpty) return valor;
    } catch (_) {
      // APNs aún no listo: se reintenta.
    }
    if (intento < esperas.length) await pausa(esperas[intento]);
  }
  return null;
}
