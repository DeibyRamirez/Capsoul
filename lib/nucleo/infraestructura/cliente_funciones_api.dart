import 'dart:convert';

import '../../funcionalidades/elementos/dominio/tipo_elemento.dart';
import '../../funcionalidades/recuerdos/dominio/url_medio.dart';

/// Firma de Cloudinary que devuelve el servidor (`firmar-subida`).
class FirmaSubida {
  const FirmaSubida({
    required this.urlSubida,
    required this.parametros,
  });

  final String urlSubida;
  final Map<String, String> parametros;

  static FirmaSubida? desdeJson(Object? datos) {
    if (datos is! Map) return null;
    final url = datos['url_subida'];
    final parametros = datos['parametros'];
    if (url is! String || !url.startsWith('https://') || parametros is! Map) {
      return null;
    }
    final campos = <String, String>{};
    for (final entrada in parametros.entries) {
      final valor = entrada.value;
      if (entrada.key is! String || valor == null) return null;
      campos[entrada.key as String] = '$valor';
    }
    for (final requerido
        in const ['api_key', 'timestamp', 'signature', 'public_id']) {
      if (!campos.containsKey(requerido)) return null;
    }
    return FirmaSubida(urlSubida: url, parametros: Map.unmodifiable(campos));
  }
}

/// Respuesta de error de la API de funciones.
class ErrorFuncionesApi implements Exception {
  const ErrorFuncionesApi({required this.estado, this.detalles});

  final int estado;
  final Object? detalles;
}

/// Cuerpo JSON de error de una Edge Function (`codigo`, `mensaje`).
Map<String, dynamic>? mapaDetallesErrorFunciones(Object? detalles) {
  if (detalles is Map<String, dynamic>) return detalles;
  if (detalles is Map) return Map<String, dynamic>.from(detalles);
  if (detalles is String) {
    try {
      final decodificado = jsonDecode(detalles);
      if (decodificado is Map) {
        return Map<String, dynamic>.from(decodificado);
      }
    } on FormatException {
      return null;
    }
  }
  return null;
}

/// Mensaje en español devuelto por el servidor, o [porDefecto].
String mensajeErrorFuncionesApi(
  ErrorFuncionesApi error, {
  required String porDefecto,
}) {
  final mapa = mapaDetallesErrorFunciones(error.detalles);
  final mensaje = mapa?['mensaje'];
  if (mensaje is String && mensaje.trim().isNotEmpty) {
    return mensaje.trim();
  }
  if (error.estado == 401) {
    return 'Inicia sesión de nuevo para buscar música.';
  }
  return porDefecto;
}

/// Contrato para firmar subidas y entregas de medios.
abstract interface class ClienteFuncionesApi {
  Future<FirmaSubida> firmarSubida({
    required TipoElemento tipo,
    required int bytes,
    Duration? duracion,
    String? formato,
  });

  Future<List<UrlMedio>> firmarMedio(List<String> idsElemento);

  /// Resultados normalizados de la Edge Function `buscar-musica`.
  Future<List<Map<String, dynamic>>> buscarMusica({
    required String consulta,
    int limite = 10,
    String mercado = 'CO',
  });
}
