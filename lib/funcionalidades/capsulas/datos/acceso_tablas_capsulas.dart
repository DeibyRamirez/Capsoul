import '../../../nucleo/infraestructura/cliente_postgrest.dart';
import '../../recuerdos/datos/mapeo_recuerdos.dart';

abstract interface class AccesoTablasCapsulas {
  Future<void> insertarCapsula(Map<String, dynamic> fila);

  Future<void> insertarEnlaces(List<Map<String, dynamic>> filas);

  Future<void> insertarDestinatarios(List<Map<String, dynamic>> filas);

  Future<void> actualizarEstadoCapsula(String id, String estado);

  Future<void> eliminarCapsula(String id);

  Future<List<Map<String, dynamic>>> leerCapsulasDeAutor(String autorId);

  Future<Map<String, dynamic>?> leerCapsulaConElementos(String id);

  /// `abierta_en` del usuario en `capsula_destinatarios` (no viene en el RPC).
  Future<List<Map<String, dynamic>>> leerAperturasDeUsuario(String usuarioId);

  Future<void> actualizarCapsula(String id, Map<String, dynamic> cambios);

  Future<List<Map<String, dynamic>>> leerCapsulasRecibidas();

  Future<void> marcarCapsulaAbierta(String idCapsula);

  Future<void> eliminarEnlacesDeCapsula(String capsulaId);

  Future<void> eliminarDestinatariosDeCapsula(String capsulaId);
}

class AccesoTablasCapsulasPostgrest implements AccesoTablasCapsulas {
  AccesoTablasCapsulasPostgrest(this._cliente);

  static const String columnasCapsula =
      'id, autor_id, titulo, mensaje, fecha_apertura, estado, liberada_en, '
      'creado_en';

  static const String columnasConElementos = '$columnasCapsula, '
      'capsula_elementos(orden, elementos($columnasRecuerdo))';

  static const String columnasDestinatarios =
      'capsula_destinatarios(usuario_id, correo_externo, abierta_en)';

  static const String columnasLista = '$columnasCapsula, $columnasDestinatarios';

  static const String columnasConElementosYDestinatarios =
      '$columnasConElementos, $columnasDestinatarios';

  static const int limiteLista = 50;

  static const int limiteAperturas = 1000;

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
  Future<void> insertarDestinatarios(List<Map<String, dynamic>> filas) async {
    if (filas.isEmpty) return;
    await _cliente.from('capsula_destinatarios').insertarMuchos(filas);
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
        .seleccionar(columnasLista)
        .eq('autor_id', autorId)
        .order('creado_en', ascendente: false)
        .limit(limiteLista)
        .ejecutar();
  }

  @override
  Future<Map<String, dynamic>?> leerCapsulaConElementos(String id) {
    return _cliente
        .from('capsulas')
        .seleccionar(columnasConElementosYDestinatarios)
        .eq('id', id)
        .maybeSingle();
  }

  @override
  Future<void> actualizarCapsula(String id, Map<String, dynamic> cambios) async {
    await _cliente.from('capsulas').actualizar(cambios).eq('id', id).ejecutar();
  }

  @override
  Future<List<Map<String, dynamic>>> leerAperturasDeUsuario(String usuarioId) {
    return _cliente
        .from('capsula_destinatarios')
        .seleccionar('capsula_id, abierta_en')
        .eq('usuario_id', usuarioId)
        .limit(limiteAperturas)
        .ejecutar();
  }

  @override
  Future<List<Map<String, dynamic>>> leerCapsulasRecibidas() async {
    final filas = await _cliente.rpc('capsulas_recibidas');
    return [
      for (final fila in filas)
        if (fila is Map<String, dynamic>) fila,
    ];
  }

  @override
  Future<void> marcarCapsulaAbierta(String idCapsula) async {
    await _cliente.rpc(
      'marcar_capsula_abierta',
      parametros: {'p_capsula': idCapsula},
    );
  }

  @override
  Future<void> eliminarEnlacesDeCapsula(String capsulaId) async {
    await _cliente
        .from('capsula_elementos')
        .eliminar()
        .eq('capsula_id', capsulaId)
        .ejecutar();
  }

  @override
  Future<void> eliminarDestinatariosDeCapsula(String capsulaId) async {
    await _cliente
        .from('capsula_destinatarios')
        .eliminar()
        .eq('capsula_id', capsulaId)
        .ejecutar();
  }
}
