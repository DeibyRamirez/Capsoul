import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../funcionalidades/elementos/dominio/tipo_elemento.dart';
import '../../../../funcionalidades/recuerdos/dominio/url_medio.dart';
import '../../cliente_funciones_api.dart';

/// [ClienteFuncionesApi] que invoca Edge Functions de Supabase.
class ClienteFuncionesSupabase implements ClienteFuncionesApi {
  ClienteFuncionesSupabase({SupabaseClient? cliente})
      : _cliente = cliente ?? Supabase.instance.client;

  static const String funcionFirmarSubida = 'firmar-subida';
  static const String funcionFirmarMedio = 'firmar-medio';
  static const String funcionBuscarMusica = 'buscar-musica';

  final SupabaseClient _cliente;

  @override
  Future<FirmaSubida> firmarSubida({
    required TipoElemento tipo,
    required int bytes,
    Duration? duracion,
    String? formato,
  }) async {
    try {
      final respuesta = await _cliente.functions.invoke(
        funcionFirmarSubida,
        body: {
          'tipo': tipo.valorBd,
          'bytes': bytes,
          if (duracion != null)
            'duracion_segundos': duracion.inMilliseconds / 1000,
          'formato': ?formato,
        },
      );
      final firma = FirmaSubida.desdeJson(respuesta.data);
      if (firma == null) {
        throw const ErrorFuncionesApi(estado: 500, detalles: 'respuesta_invalida');
      }
      return firma;
    } on FunctionException catch (error) {
      throw ErrorFuncionesApi(estado: error.status, detalles: error.details);
    }
  }

  @override
  Future<List<UrlMedio>> firmarMedio(List<String> idsElemento) async {
    try {
      final respuesta = await _cliente.functions.invoke(
        funcionFirmarMedio,
        body: {'elemento_ids': idsElemento},
      );
      final datos = respuesta.data;
      final medios = datos is Map ? datos['medios'] : null;
      if (medios is! List) return const [];
      return [for (final medio in medios) ?UrlMedio.desdeJson(medio)];
    } on FunctionException catch (error) {
      throw ErrorFuncionesApi(estado: error.status, detalles: error.details);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> buscarMusica({
    required String consulta,
    int limite = 10,
    String mercado = 'CO',
  }) async {
    try {
      final respuesta = await _cliente.functions.invoke(
        funcionBuscarMusica,
        body: {
          'consulta': consulta,
          'limite': limite,
          'mercado': mercado,
        },
      );
      final datos = respuesta.data;
      final resultados = datos is Map ? datos['resultados'] : null;
      if (resultados is! List) return const [];
      return [
        for (final item in resultados)
          if (item is Map<String, dynamic>) item else if (item is Map) Map<String, dynamic>.from(item),
      ];
    } on FunctionException catch (error) {
      debugPrint(
        'Capsoul buscar-musica: HTTP ${error.status} ${error.details}',
      );
      throw ErrorFuncionesApi(estado: error.status, detalles: error.details);
    }
  }
}
