import '../../../nucleo/infraestructura/cliente_postgrest.dart';
import 'mapeo_recuerdos.dart';

abstract interface class AccesoTablasRecuerdos {
  Future<void> insertar(Map<String, dynamic> fila);

  Future<List<Map<String, dynamic>>> listar({
    required String propietarioId,
    List<String> tipos = const [],
    String? desde,
    String? hasta,
    int limite = 200,
  });

  Future<Map<String, dynamic>?> leerPorId(String id);

  Future<int> contarCapsulasSelladas(String id);

  Future<int> eliminar(String id);

  Future<Map<String, dynamic>?> leerUsoMedios();
}

class AccesoTablasRecuerdosPostgrest implements AccesoTablasRecuerdos {
  AccesoTablasRecuerdosPostgrest(this._cliente);

  final ClientePostgrest _cliente;

  @override
  Future<void> insertar(Map<String, dynamic> fila) async {
    await _cliente.from('elementos').insertar(fila);
  }

  @override
  Future<List<Map<String, dynamic>>> listar({
    required String propietarioId,
    List<String> tipos = const [],
    String? desde,
    String? hasta,
    int limite = 200,
  }) {
    var consulta = _cliente
        .from('elementos')
        .seleccionar(columnasRecuerdo)
        .eq('propietario_id', propietarioId);
    if (tipos.isNotEmpty) consulta = consulta.inFilter('tipo', tipos);
    if (desde != null) consulta = consulta.gte('fecha_recuerdo', desde);
    if (hasta != null) consulta = consulta.lte('fecha_recuerdo', hasta);
    return consulta
        .order('fecha_recuerdo', ascendente: false)
        .order('creado_en', ascendente: false)
        .limit(limite)
        .ejecutar();
  }

  @override
  Future<Map<String, dynamic>?> leerPorId(String id) {
    return _cliente
        .from('elementos')
        .seleccionar(columnasRecuerdo)
        .eq('id', id)
        .maybeSingle();
  }

  @override
  Future<int> contarCapsulasSelladas(String id) async {
    final filas = await _cliente
        .from('capsula_elementos')
        .seleccionar('capsula_id, capsulas!inner(estado)')
        .eq('elemento_id', id)
        .inFilter('capsulas.estado', const ['programada', 'liberada'])
        .ejecutar();
    return filas.length;
  }

  @override
  Future<int> eliminar(String id) async {
    final borradas =
        await _cliente.from('elementos').eliminar().eq('id', id).select('id');
    return borradas.length;
  }

  @override
  Future<Map<String, dynamic>?> leerUsoMedios() async {
    final filas = await _cliente.rpc('mi_uso_medios');
    final primera = filas.isEmpty ? null : filas.first;
    return primera is Map<String, dynamic> ? primera : null;
  }
}
