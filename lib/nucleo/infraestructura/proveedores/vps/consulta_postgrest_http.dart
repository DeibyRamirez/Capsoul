import 'dart:convert';

import '../../consulta_postgrest.dart';
import 'cliente_postgrest_http.dart';

class SeleccionPostgrestHttp implements SeleccionPostgrest {
  SeleccionPostgrestHttp(this._tabla, this._cliente, this._columnas);

  final String _tabla;
  final ClientePostgrestHttp _cliente;
  final String _columnas;
  final Map<String, String> _filtros = {};
  final List<String> _orden = [];
  int? _limite;

  @override
  SeleccionPostgrest eq(String columna, Object valor) {
    _filtros[columna] = 'eq.$valor';
    return this;
  }

  @override
  SeleccionPostgrest neq(String columna, Object valor) {
    _filtros[columna] = 'neq.$valor';
    return this;
  }

  @override
  SeleccionPostgrest gte(String columna, Object valor) {
    _filtros[columna] = 'gte.$valor';
    return this;
  }

  @override
  SeleccionPostgrest lte(String columna, Object valor) {
    _filtros[columna] = 'lte.$valor';
    return this;
  }

  @override
  SeleccionPostgrest inFilter(String columna, List<Object> valores) {
    _filtros[columna] = 'in.(${valores.join(',')})';
    return this;
  }

  @override
  SeleccionPostgrest order(String columna, {bool ascendente = true}) {
    _orden.add('$columna.${ascendente ? 'asc' : 'desc'}');
    return this;
  }

  @override
  SeleccionPostgrest limit(int cantidad) {
    _limite = cantidad;
    return this;
  }

  Map<String, String> _queryBase() => {
        'select': _columnas,
        ..._filtros,
        if (_orden.isNotEmpty) 'order': _orden.join(','),
        if (_limite != null) 'limit': '$_limite',
      };

  @override
  Future<List<Map<String, dynamic>>> ejecutar() async {
    final respuesta = await _cliente.get(_tabla, query: _queryBase());
    ClientePostgrestHttp.verificarRespuesta(respuesta);
    final datos = jsonDecode(respuesta.body);
    if (datos is List) {
      return List<Map<String, dynamic>>.from(datos);
    }
    if (datos is Map<String, dynamic>) return [datos];
    return const [];
  }

  @override
  Future<Map<String, dynamic>?> maybeSingle() async {
    final filas = await limit(1).ejecutar();
    return filas.isEmpty ? null : filas.first;
  }

  @override
  Future<ConteoPostgrest> contar() async {
    final conteoRespuesta = await _cliente.clienteHttp.head(
      _cliente.uri(_tabla, {
        ..._filtros,
        'select': _columnas,
      }),
      headers: {
        ..._cliente.cabeceras(),
        'Prefer': 'count=exact',
      },
    );
    ClientePostgrestHttp.verificarRespuesta(conteoRespuesta);
    final rango = conteoRespuesta.headers['content-range'];
    if (rango != null && rango.contains('/')) {
      final total = rango.split('/').last;
      return ConteoPostgrest(int.tryParse(total) ?? 0);
    }
    return const ConteoPostgrest(0);
  }
}

class ActualizacionPostgrestHttp implements ActualizacionPostgrest {
  ActualizacionPostgrestHttp(this._tabla, this._cliente, this._valores);

  final String _tabla;
  final ClientePostgrestHttp _cliente;
  final Map<String, dynamic> _valores;
  final Map<String, String> _filtros = {};

  @override
  ActualizacionPostgrest eq(String columna, Object valor) {
    _filtros[columna] = 'eq.$valor';
    return this;
  }

  @override
  Future<List<Map<String, dynamic>>> select(String columnas) async {
    final respuesta = await _cliente.patch(
      _tabla,
      cuerpo: _valores,
      query: _filtros,
      cabecerasExtra: {'Prefer': 'return=representation'},
    );
    ClientePostgrestHttp.verificarRespuesta(respuesta);
    final datos = jsonDecode(respuesta.body);
    if (datos is List) return List<Map<String, dynamic>>.from(datos);
    if (datos is Map<String, dynamic>) return [datos];
    return const [];
  }

  @override
  Future<void> ejecutar() async {
    final respuesta = await _cliente.patch(
      _tabla,
      cuerpo: _valores,
      query: _filtros,
    );
    ClientePostgrestHttp.verificarRespuesta(respuesta);
  }
}

class EliminacionPostgrestHttp implements EliminacionPostgrest {
  EliminacionPostgrestHttp(this._tabla, this._cliente);

  final String _tabla;
  final ClientePostgrestHttp _cliente;
  final Map<String, String> _filtros = {};

  @override
  EliminacionPostgrest eq(String columna, Object valor) {
    _filtros[columna] = 'eq.$valor';
    return this;
  }

  @override
  Future<List<Map<String, dynamic>>> select(String columnas) async {
    final respuesta = await _cliente.delete(
      _tabla,
      query: {
        ..._filtros,
        'select': columnas,
      },
      cabecerasExtra: {'Prefer': 'return=representation'},
    );
    ClientePostgrestHttp.verificarRespuesta(respuesta);
    final datos = jsonDecode(respuesta.body);
    if (datos is List) return List<Map<String, dynamic>>.from(datos);
    return const [];
  }

  @override
  Future<void> ejecutar() async {
    final respuesta = await _cliente.delete(_tabla, query: _filtros);
    ClientePostgrestHttp.verificarRespuesta(respuesta);
  }
}
