import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../cliente_postgrest.dart';
import '../../configuracion_backend.dart';
import '../../consulta_postgrest.dart';
import '../../traductor_errores_backend.dart';
import 'consulta_postgrest_http.dart';

/// [ClientePostgrest] que habla con PostgREST vía HTTP (modo VPS).
class ClientePostgrestHttp implements ClientePostgrest {
  ClientePostgrestHttp({
    required this.tokenAcceso,
    http.Client? clienteHttp,
    String? urlBase,
  })  : _clienteHttp = clienteHttp ?? http.Client(),
        urlBase = (urlBase ?? ConfiguracionBackend.postgrestUrl).trim();

  final http.Client _clienteHttp;
  http.Client get clienteHttp => _clienteHttp;
  final String urlBase;
  String? tokenAcceso;

  Map<String, String> cabeceras({bool json = false}) => {
        if (tokenAcceso != null) 'Authorization': 'Bearer $tokenAcceso',
        'apikey': ConfiguracionBackend.clavePublica,
        if (json) 'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Uri uri(String ruta, [Map<String, String>? query]) {
    final base = urlBase.endsWith('/') ? urlBase : '$urlBase/';
    return Uri.parse('$base$ruta').replace(queryParameters: query);
  }

  @override
  TablaPostgrest from(String tabla) => TablaPostgrestHttp(tabla, this);

  @override
  Future<List<dynamic>> rpc(
    String nombre, {
    Map<String, dynamic>? parametros,
  }) async {
    final respuesta = await _clienteHttp.post(
      uri('rpc/$nombre'),
      headers: cabeceras(json: true),
      body: jsonEncode(parametros ?? {}),
    );
    verificarRespuesta(respuesta);
    final datos = jsonDecode(respuesta.body);
    if (datos is List) return datos;
    if (datos == null) return const [];
    return [datos];
  }

  Future<http.Response> get(String ruta, {Map<String, String>? query}) =>
      _clienteHttp.get(uri(ruta, query), headers: cabeceras());

  Future<http.Response> post(
    String ruta, {
    Object? cuerpo,
    Map<String, String>? query,
    Map<String, String>? cabecerasExtra,
  }) =>
      _clienteHttp.post(
        uri(ruta, query),
        headers: {...cabeceras(json: true), ...?cabecerasExtra},
        body: cuerpo == null ? null : jsonEncode(cuerpo),
      );

  Future<http.Response> patch(
    String ruta, {
    required Object cuerpo,
    Map<String, String>? query,
    Map<String, String>? cabecerasExtra,
  }) =>
      _clienteHttp.patch(
        uri(ruta, query),
        headers: {...cabeceras(json: true), ...?cabecerasExtra},
        body: jsonEncode(cuerpo),
      );

  Future<http.Response> delete(
    String ruta, {
    Map<String, String>? query,
    Map<String, String>? cabecerasExtra,
  }) =>
      _clienteHttp.delete(
        uri(ruta, query),
        headers: {...cabeceras(), ...?cabecerasExtra},
      );

  static void verificarRespuesta(http.Response respuesta) {
    if (respuesta.statusCode >= 200 && respuesta.statusCode < 300) return;
    String? codigo;
    String mensaje = respuesta.body;
    try {
      final datos = jsonDecode(respuesta.body);
      if (datos is Map) {
        codigo = datos['code'] as String?;
        mensaje = (datos['message'] ?? datos['hint'] ?? respuesta.body)
            .toString();
      }
    } on FormatException {
      // Cuerpo no JSON.
    }
    throw ErrorPostgrest(codigo: codigo, mensaje: mensaje);
  }

  void liberarRecursos() => _clienteHttp.close();
}

/// Tabla PostgREST vía HTTP.
class TablaPostgrestHttp implements TablaPostgrest {
  TablaPostgrestHttp(this._tabla, this._cliente);

  final String _tabla;
  final ClientePostgrestHttp _cliente;

  @override
  Future<void> insertar(Map<String, dynamic> fila) async {
    final respuesta = await _cliente.post(_tabla, cuerpo: fila);
    ClientePostgrestHttp.verificarRespuesta(respuesta);
  }

  @override
  Future<void> insertarMuchos(List<Map<String, dynamic>> filas) async {
    final respuesta = await _cliente.post(_tabla, cuerpo: filas);
    ClientePostgrestHttp.verificarRespuesta(respuesta);
  }

  @override
  SeleccionPostgrest seleccionar([String columnas = '*']) =>
      SeleccionPostgrestHttp(_tabla, _cliente, columnas);

  @override
  ActualizacionPostgrest actualizar(Map<String, dynamic> valores) =>
      ActualizacionPostgrestHttp(_tabla, _cliente, valores);

  @override
  EliminacionPostgrest eliminar() =>
      EliminacionPostgrestHttp(_tabla, _cliente);
}
