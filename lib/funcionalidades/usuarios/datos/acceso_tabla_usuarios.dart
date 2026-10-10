import '../../../nucleo/infraestructura/cliente_postgrest.dart';

/// Capa mínima sobre PostgREST para la tabla `usuarios`.
abstract interface class AccesoTablaUsuarios {
  Future<Map<String, dynamic>?> leerFila(String id);

  Future<int> actualizarNombreVisible(String id, String nombreVisible);
}

class AccesoTablaUsuariosPostgrest implements AccesoTablaUsuarios {
  AccesoTablaUsuariosPostgrest(this._cliente);

  static const String tabla = 'usuarios';

  static const String columnas =
      'id, nombre_visible, correo, foto_public_id, perfil_publico, creado_en';

  final ClientePostgrest _cliente;

  @override
  Future<Map<String, dynamic>?> leerFila(String id) {
    return _cliente
        .from(tabla)
        .seleccionar(columnas)
        .eq('id', id)
        .maybeSingle();
  }

  @override
  Future<int> actualizarNombreVisible(String id, String nombreVisible) async {
    final filas = await _cliente
        .from(tabla)
        .actualizar({'nombre_visible': nombreVisible})
        .eq('id', id)
        .select('id');
    return filas.length;
  }
}
