import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../funcionalidades/elementos/dominio/tipo_elemento.dart';
import '../../../../funcionalidades/recuerdos/dominio/url_medio.dart';
import '../../cliente_autenticacion.dart';
import '../../cliente_funciones_api.dart';
import '../../configuracion_backend.dart';

/// [ClienteFuncionesApi] que llama a la API Capsoul en el VPS.
class ClienteFuncionesHttp implements ClienteFuncionesApi {
  ClienteFuncionesHttp({
    required ClienteAutenticacion autenticacion,
    http.Client? clienteHttp,
    String? urlBase,
  })  : _autenticacion = autenticacion,
        _http = clienteHttp ?? http.Client(),
        _urlBase = (urlBase ?? ConfiguracionBackend.apiBaseUrl).trim();

  final ClienteAutenticacion _autenticacion;
  final http.Client _http;
  final String _urlBase;

  Uri _uri(String ruta) {
    final base = _urlBase.endsWith('/') ? _urlBase : '$_urlBase/';
    return Uri.parse('$base$ruta');
  }

  Map<String, String> _cabeceras() => {
        'Content-Type': 'application/json',
        if (_autenticacion.tokenAcceso != null)
          'Authorization': 'Bearer ${_autenticacion.tokenAcceso}',
      };

  @override
  Future<FirmaSubida> firmarSubida({
    required TipoElemento tipo,
    required int bytes,
    Duration? duracion,
    String? formato,
  }) async {
    final respuesta = await _http.post(
      _uri('v1/medios/firmar-subida'),
      headers: _cabeceras(),
      body: jsonEncode({
        'tipo': tipo.valorBd,
        'bytes': bytes,
        if (duracion != null)
          'duracion_segundos': duracion.inMilliseconds / 1000,
        'formato': ?formato,
      }),
    );
    if (respuesta.statusCode >= 200 && respuesta.statusCode < 300) {
      final firma = FirmaSubida.desdeJson(jsonDecode(respuesta.body));
      if (firma != null) return firma;
    }
    Object? detalles;
    try {
      detalles = jsonDecode(respuesta.body);
    } on FormatException {
      detalles = respuesta.body;
    }
    throw ErrorFuncionesApi(estado: respuesta.statusCode, detalles: detalles);
  }

  @override
  Future<List<UrlMedio>> firmarMedio(List<String> idsElemento) async {
    final respuesta = await _http.post(
      _uri('v1/medios/firmar-entrega'),
      headers: _cabeceras(),
      body: jsonEncode({'elemento_ids': idsElemento}),
    );
    if (respuesta.statusCode >= 200 && respuesta.statusCode < 300) {
      final datos = jsonDecode(respuesta.body);
      final medios = datos is Map ? datos['medios'] : null;
      if (medios is List) {
        return [for (final medio in medios) ?UrlMedio.desdeJson(medio)];
      }
      return const [];
    }
    throw ErrorFuncionesApi(
      estado: respuesta.statusCode,
      detalles: respuesta.body,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> buscarMusica({
    required String consulta,
    int limite = 10,
    String mercado = 'CO',
  }) async {
    final respuesta = await _http.post(
      _uri('v1/musica/buscar'),
      headers: _cabeceras(),
      body: jsonEncode({
        'consulta': consulta,
        'limite': limite,
        'mercado': mercado,
      }),
    );
    if (respuesta.statusCode >= 200 && respuesta.statusCode < 300) {
      final datos = jsonDecode(respuesta.body);
      final resultados = datos is Map ? datos['resultados'] : null;
      if (resultados is List) {
        return [
          for (final item in resultados)
            if (item is Map<String, dynamic>)
              item
            else if (item is Map)
              Map<String, dynamic>.from(item),
        ];
      }
      return const [];
    }
    throw ErrorFuncionesApi(
      estado: respuesta.statusCode,
      detalles: respuesta.body,
    );
  }

  void liberarRecursos() => _http.close();
}
