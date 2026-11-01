import 'capsula_recibida.dart';

/// Cápsulas liberadas que otra persona me envió, de la más nueva a la más vieja.
///
/// El contador del badge usa [conteoAvisosSinLeer]: `leida_en` vacío.
/// `abierta_en` no entra aquí; abrir el frasco es otro gesto.
List<CapsulaRecibida> avisosCapsulasCompartidas(
  List<CapsulaRecibida> recibidas,
  String? uid,
) {
  final avisos = [
    for (final recibida in recibidas)
      if (recibida.estaLiberada && (uid == null || recibida.autorId != uid))
        recibida,
  ];
  avisos.sort((a, b) {
    final fechaA = a.liberadaEn ?? a.fechaApertura;
    final fechaB = b.liberadaEn ?? b.fechaApertura;
    return fechaB.compareTo(fechaA);
  });
  return avisos;
}

/// Cápsulas sin leer más solicitudes de amistad que aún no respondí.
int conteoPendientesAvisos({
  required int capsulasSinLeer,
  required int solicitudesPendientes,
}) {
  final capsulas = capsulasSinLeer < 0 ? 0 : capsulasSinLeer;
  final solicitudes = solicitudesPendientes < 0 ? 0 : solicitudesPendientes;
  return capsulas + solicitudes;
}

/// Avisos que todavía no vi.
int conteoAvisosSinLeer(List<CapsulaRecibida> avisos) {
  var n = 0;
  for (final aviso in avisos) {
    if (aviso.leidaEn == null) n++;
  }
  return n;
}

/// Texto del badge. `null` lo oculta. Más de 9 se muestra como «9+».
String? textoBadgeAvisos(int conteo) {
  if (conteo <= 0) return null;
  if (conteo > 9) return '9+';
  return '$conteo';
}
