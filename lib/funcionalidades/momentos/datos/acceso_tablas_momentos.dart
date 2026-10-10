import '../../../nucleo/infraestructura/cliente_postgrest.dart';
import '../../recuerdos/datos/mapeo_recuerdos.dart';

abstract interface class AccesoTablasMomentos {
  Future<void> insertarMomento(Map<String, dynamic> fila);

  Future<void> insertarEnlaces(List<Map<String, dynamic>> filas);

  Future<void> actualizarPortada(String id, String? elementoId);

  Future<int> eliminarMomento(String id);

  Future<List<Map<String, dynamic>>> listarDeAutor(String autorId);

  Future<Map<String, dynamic>?> leerConRecuerdos(String id);
}

class AccesoTablasMomentosPostgrest implements AccesoTablasMomentos {
  AccesoTablasMomentosPostgrest(this._cliente);

  static const String columnasMomento =
      'id, autor_id, titulo, texto, creado_en, '
      'portada:elementos!momentos_portada_elemento_id_fkey($columnasRecuerdo)';

  static const String columnasListado =
      '$columnasMomento, momento_elementos(orden, elementos($columnasRecuerdo))';

  static const String columnasDetalle =
      '$columnasMomento, momento_elementos(orden, elementos($columnasRecuerdo))';

  static const int limiteLista = 100;

  final ClientePostgrest _cliente;

  @override
  Future<void> insertarMomento(Map<String, dynamic> fila) async {
    await _cliente.from('momentos').insertar(fila);
  }

  @override
  Future<void> insertarEnlaces(List<Map<String, dynamic>> filas) async {
    if (filas.isEmpty) return;
    await _cliente.from('momento_elementos').insertarMuchos(filas);
  }

  @override
  Future<void> actualizarPortada(String id, String? elementoId) async {
    await _cliente
        .from('momentos')
        .actualizar({'portada_elemento_id': elementoId})
        .eq('id', id)
        .ejecutar();
  }

  @override
  Future<int> eliminarMomento(String id) async {
    final borradas =
        await _cliente.from('momentos').eliminar().eq('id', id).select('id');
    return borradas.length;
  }

  @override
  Future<List<Map<String, dynamic>>> listarDeAutor(String autorId) {
    return _cliente
        .from('momentos')
        .seleccionar(columnasListado)
        .eq('autor_id', autorId)
        .order('creado_en', ascendente: false)
        .limit(limiteLista)
        .ejecutar();
  }

  @override
  Future<Map<String, dynamic>?> leerConRecuerdos(String id) {
    return _cliente
        .from('momentos')
        .seleccionar(columnasDetalle)
        .eq('id', id)
        .maybeSingle();
  }
}
