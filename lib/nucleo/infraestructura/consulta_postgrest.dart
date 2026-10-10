/// Orden de una consulta PostgREST.
class OrdenColumna {
  const OrdenColumna(this.columna, {this.ascendente = true});

  final String columna;
  final bool ascendente;
}

/// Consulta de lectura sobre una tabla PostgREST.
abstract interface class SeleccionPostgrest {
  SeleccionPostgrest eq(String columna, Object valor);
  SeleccionPostgrest neq(String columna, Object valor);
  SeleccionPostgrest gte(String columna, Object valor);
  SeleccionPostgrest lte(String columna, Object valor);
  SeleccionPostgrest inFilter(String columna, List<Object> valores);
  SeleccionPostgrest order(String columna, {bool ascendente = true});
  SeleccionPostgrest limit(int cantidad);

  Future<List<Map<String, dynamic>>> ejecutar();
  Future<Map<String, dynamic>?> maybeSingle();
  Future<ConteoPostgrest> contar();
}

/// Resultado de un conteo exacto.
class ConteoPostgrest {
  const ConteoPostgrest(this.cantidad);

  final int cantidad;
}

/// Actualización condicionada sobre una tabla.
abstract interface class ActualizacionPostgrest {
  ActualizacionPostgrest eq(String columna, Object valor);
  Future<List<Map<String, dynamic>>> select(String columnas);
  Future<void> ejecutar();
}

/// Borrado condicionado sobre una tabla.
abstract interface class EliminacionPostgrest {
  EliminacionPostgrest eq(String columna, Object valor);
  Future<List<Map<String, dynamic>>> select(String columnas);
  Future<void> ejecutar();
}

/// Punto de entrada a una tabla PostgREST.
abstract interface class TablaPostgrest {
  Future<void> insertar(Map<String, dynamic> fila);
  Future<void> insertarMuchos(List<Map<String, dynamic>> filas);
  SeleccionPostgrest seleccionar([String columnas]);
  ActualizacionPostgrest actualizar(Map<String, dynamic> valores);
  EliminacionPostgrest eliminar();
}
