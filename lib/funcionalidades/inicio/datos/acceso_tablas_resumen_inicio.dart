import '../../../nucleo/infraestructura/cliente_postgrest.dart';

/// Conteo de filas con filtros (adaptador delgado sobre PostgREST).
abstract interface class AccesoTablasResumenInicio {
  Future<int> contar(
    String tabla, {
    required Map<String, String> iguales,
    Map<String, String> distintos,
  });

  Future<int> contarRetosPendientes();
}

class AccesoTablasResumenInicioPostgrest implements AccesoTablasResumenInicio {
  AccesoTablasResumenInicioPostgrest(this._cliente);

  final ClientePostgrest _cliente;

  @override
  Future<int> contar(
    String tabla, {
    required Map<String, String> iguales,
    Map<String, String> distintos = const {},
  }) async {
    var consulta = _cliente.from(tabla).seleccionar('id');
    for (final filtro in iguales.entries) {
      consulta = consulta.eq(filtro.key, filtro.value);
    }
    for (final filtro in distintos.entries) {
      consulta = consulta.neq(filtro.key, filtro.value);
    }
    final respuesta = await consulta.limit(1).contar();
    return respuesta.cantidad;
  }

  @override
  Future<int> contarRetosPendientes() async {
    final filas = await _cliente.rpc('contar_retos_pendientes');
    if (filas.isEmpty) return 0;
    final valor = filas.first;
    if (valor is int) return valor;
    if (valor is num) return valor.toInt();
    return 0;
  }
}
