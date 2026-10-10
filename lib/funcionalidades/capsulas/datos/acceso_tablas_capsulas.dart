import '../../../nucleo/infraestructura/cliente_postgrest.dart';
import '../../recuerdos/datos/mapeo_recuerdos.dart';

abstract interface class AccesoTablasCapsulas {
  Future<void> insertarCapsula(Map<String, dynamic> fila);

  Future<void> insertarEnlaces(List<Map<String, dynamic>> filas);

  Future<void> actualizarEstadoCapsula(String id, String estado);

  Future<void> eliminarCapsula(String id);

  Future<List<Map<String, dynamic>>> leerCapsulasDeAutor(String autorId);

  Future<Map<String, dynamic>?> leerCapsulaConElementos(String id);
}

class AccesoTablasCapsulasPostgrest implements AccesoTablasCapsulas {
  AccesoTablasCapsulasPostgrest(this._cliente);

  static const String columnasCapsula =
      'id, autor_id, titulo, mensaje, fecha_apertura, estado, liberada_en, '
      'creado_en';

  static const String columnasConElementos = '$columnasCapsula, '
      'capsula_elementos(orden, elementos($columnasRecuerdo))';

  static const int limiteLista = 50;

  final ClientePostgrest _cliente;

  @override
  Future<void> insertarCapsula(Map<String, dynamic> fila) async {
    await _cliente.from('capsulas').insertar(fila);
  }

  @override
  Future<void> insertarEnlaces(List<Map<String, dynamic>> filas) async {
    if (filas.isEmpty) return;
    await _cliente.from('capsula_elementos').insertarMuchos(filas);
  }

  @override
  Future<void> actualizarEstadoCapsula(String id, String estado) async {
    await _cliente
        .from('capsulas')
        .actualizar({'estado': estado})
        .eq('id', id)
        .ejecutar();
  }

  @override
  Future<void> eliminarCapsula(String id) async {
    await _cliente.from('capsulas').eliminar().eq('id', id).ejecutar();
  }

  @override
  Future<List<Map<String, dynamic>>> leerCapsulasDeAutor(String autorId) {
    return _cliente
        .from('capsulas')
        .seleccionar(columnasCapsula)
        .eq('autor_id', autorId)
        .neq('estado', 'cancelada')
        .order('creado_en', ascendente: false)
        .limit(limiteLista)
        .ejecutar();
  }

  @override
  Future<Map<String, dynamic>?> leerCapsulaConElementos(String id) {
    return _cliente
        .from('capsulas')
        .seleccionar(columnasConElementos)
        .eq('id', id)
        .maybeSingle();
  }
}
