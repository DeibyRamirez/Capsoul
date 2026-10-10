import 'package:supabase_flutter/supabase_flutter.dart';

import '../../consulta_postgrest.dart';
import '../../traductor_errores_backend.dart';

Future<T> protegerPostgrest<T>(Future<T> Function() accion) async {
  try {
    return await accion();
  } on PostgrestException catch (error) {
    throw ErrorPostgrest(codigo: error.code, mensaje: error.message);
  }
}

class TablaPostgrestSupabase implements TablaPostgrest {
  TablaPostgrestSupabase(this._from);

  final SupabaseQueryBuilder _from;

  @override
  Future<void> insertar(Map<String, dynamic> fila) =>
      protegerPostgrest(() => _from.insert(fila));

  @override
  Future<void> insertarMuchos(List<Map<String, dynamic>> filas) =>
      protegerPostgrest(() => _from.insert(filas));

  @override
  SeleccionPostgrest seleccionar([String columnas = '*']) =>
      SeleccionPostgrestSupabase(_from.select(columnas));

  @override
  ActualizacionPostgrest actualizar(Map<String, dynamic> valores) =>
      ActualizacionPostgrestSupabase(_from.update(valores));

  @override
  EliminacionPostgrest eliminar() =>
      EliminacionPostgrestSupabase(_from.delete());
}

class SeleccionPostgrestSupabase implements SeleccionPostgrest {
  SeleccionPostgrestSupabase(this._builder);

  dynamic _builder;

  @override
  SeleccionPostgrest eq(String columna, Object valor) {
    _builder = _builder.eq(columna, valor);
    return this;
  }

  @override
  SeleccionPostgrest neq(String columna, Object valor) {
    _builder = _builder.neq(columna, valor);
    return this;
  }

  @override
  SeleccionPostgrest gte(String columna, Object valor) {
    _builder = _builder.gte(columna, valor);
    return this;
  }

  @override
  SeleccionPostgrest lte(String columna, Object valor) {
    _builder = _builder.lte(columna, valor);
    return this;
  }

  @override
  SeleccionPostgrest inFilter(String columna, List<Object> valores) {
    _builder = _builder.inFilter(columna, valores);
    return this;
  }

  @override
  SeleccionPostgrest order(String columna, {bool ascendente = true}) {
    _builder = _builder.order(columna, ascending: ascendente);
    return this;
  }

  @override
  SeleccionPostgrest limit(int cantidad) {
    _builder = _builder.limit(cantidad);
    return this;
  }

  @override
  Future<List<Map<String, dynamic>>> ejecutar() => protegerPostgrest(
        () async => List<Map<String, dynamic>>.from(await _builder),
      );

  @override
  Future<Map<String, dynamic>?> maybeSingle() =>
      protegerPostgrest(() => _builder.maybeSingle());

  @override
  Future<ConteoPostgrest> contar() => protegerPostgrest(() async {
        final respuesta = await _builder.limit(1).count(CountOption.exact);
        return ConteoPostgrest(respuesta.count);
      });
}

class ActualizacionPostgrestSupabase implements ActualizacionPostgrest {
  ActualizacionPostgrestSupabase(this._builder);

  dynamic _builder;

  @override
  ActualizacionPostgrest eq(String columna, Object valor) {
    _builder = _builder.eq(columna, valor);
    return this;
  }

  @override
  Future<List<Map<String, dynamic>>> select(String columnas) =>
      protegerPostgrest(
        () async => List<Map<String, dynamic>>.from(
          await _builder.select(columnas),
        ),
      );

  @override
  Future<void> ejecutar() => protegerPostgrest(() => _builder);
}

class EliminacionPostgrestSupabase implements EliminacionPostgrest {
  EliminacionPostgrestSupabase(this._builder);

  dynamic _builder;

  @override
  EliminacionPostgrest eq(String columna, Object valor) {
    _builder = _builder.eq(columna, valor);
    return this;
  }

  @override
  Future<List<Map<String, dynamic>>> select(String columnas) =>
      protegerPostgrest(
        () async => List<Map<String, dynamic>>.from(
          await _builder.select(columnas),
        ),
      );

  @override
  Future<void> ejecutar() => protegerPostgrest(() => _builder);
}
