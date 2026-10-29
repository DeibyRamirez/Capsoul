import '../enlaces/enlace_capsoul.dart';
import '../enrutador/rutas_app.dart';

/// Traduce el `data.ruta` del push (`capsoul://…`) a una ruta de la app.
String? destinoInternoDeAviso(String ruta) {
  final uri = Uri.tryParse(ruta);
  if (uri == null) return null;
  final idCapsula = EnlaceCapsoul.idCapsulaDesde(uri);
  if (idCapsula != null && idCapsula.isNotEmpty) {
    return RutasApp.detalleCapsulaDe(idCapsula);
  }
  final idHerencia = EnlaceCapsoul.idHerenciaDesde(uri);
  if (idHerencia != null && idHerencia.isNotEmpty) {
    return RutasApp.detalleHerenciaDe(idHerencia);
  }
  final idReto = EnlaceCapsoul.idRetoDesde(uri);
  if (idReto != null && idReto.isNotEmpty) return RutasApp.retos;
  if (EnlaceCapsoul.esAmigos(uri)) return RutasApp.amigos;
  return null;
}
