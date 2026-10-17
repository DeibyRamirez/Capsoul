import '../../../nucleo/infraestructura/cliente_postgrest.dart';

abstract interface class AccesoTablasRetos {
  Future<List<Map<String, dynamic>>> listarGlobales();

  Future<int> contarPendientes();
}

class AccesoTablasRetosPostgrest implements AccesoTablasRetos {
  AccesoTablasRetosPostgrest(this._cliente);

  final ClientePostgrest _cliente;

  @override
  Future<List<Map<String, dynamic>>> listarGlobales() async {
    final filas = await _cliente.rpc('listar_retos_globales');
    return filas.cast<Map<String, dynamic>>();
  }

  @override
  Future<int> contarPendientes() async {
    final filas = await _cliente.rpc('contar_retos_pendientes');
    if (filas.isEmpty) return 0;
    final valor = filas.first;
    if (valor is int) return valor;
    if (valor is num) return valor.toInt();
    if (valor is Map && valor.values.isNotEmpty) {
      final interno = valor.values.first;
      if (interno is num) return interno.toInt();
    }
    return 0;
  }
}
