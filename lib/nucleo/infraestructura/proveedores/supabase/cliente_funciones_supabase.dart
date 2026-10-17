import 'dart:async';

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

  /// Evita spinner infinito si la red o la Edge Function no responden.
  static const Duration tiempoMaximoInvoke = Duration(seconds: 45);

  final SupabaseClient _cliente;

  Future<FunctionResponse> _invokeConTiempo(
    String nombre,
    Map<String, dynamic> body,
  ) {
    return _cliente.functions
        .invoke(nombre, body: body)
        .timeout(
          tiempoMaximoInvoke,
          onTimeout: () => throw TimeoutException(nombre),
        );
  }

  @override
  Future<FirmaSubida> firmarSubida({
    required TipoElemento tipo,
    required int bytes,
    Duration? duracion,
    String? formato,
    bool perfilAvatar = false,
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
          if (perfilAvatar) 'contexto': 'perfil_avatar',
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
  Future<UrlMedio?> firmarAvatarPerfil() async {
    try {
      final respuesta = await _invokeConTiempo(
        funcionFirmarMedio,
        {'avatar_perfil': true},
      );
      final datos = respuesta.data;
      final medios = datos is Map ? datos['medios'] : null;
      if (medios is! List || medios.isEmpty) {
        if (kDebugMode) {
          debugPrint(
            'Capsoul avatar: firmar-medio sin medios (revisa foto_public_id en usuarios).',
          );
        }
        return null;
      }
      final medio = UrlMedio.desdeJson(medios.first);
      if (medio == null && kDebugMode) {
        debugPrint(
          'Capsoul avatar: respuesta no parseable: ${medios.first}',
        );
      }
      return medio;
    } on TimeoutException {
      throw const ErrorFuncionesApi(
        estado: 408,
        detalles: {
          'codigo': 'tiempo_agotado',
          'mensaje': 'La firma del avatar tardó demasiado.',
        },
      );
    } on FunctionException catch (error) {
      if (kDebugMode) {
        debugPrint(
          'Capsoul avatar: firmar-medio HTTP ${error.status} ${error.details}',
        );
      }
      throw ErrorFuncionesApi(estado: error.status, detalles: error.details);
    }
  }

  @override
  Future<List<UrlMedio>> firmarAvataresUsuarios(List<String> idsUsuario) async {
    if (idsUsuario.isEmpty) return const [];
    try {
      final respuesta = await _invokeConTiempo(
        funcionFirmarMedio,
        {'avatares_usuario_ids': idsUsuario},
      );
      final datos = respuesta.data;
      final medios = datos is Map ? datos['medios'] : null;
      if (medios is! List) return const [];
      return [for (final medio in medios) ?UrlMedio.desdeJson(medio)];
    } on TimeoutException {
      throw const ErrorFuncionesApi(
        estado: 408,
        detalles: {
          'codigo': 'tiempo_agotado',
          'mensaje': 'La firma de avatares tardó demasiado.',
        },
      );
    } on FunctionException catch (error) {
      throw ErrorFuncionesApi(estado: error.status, detalles: error.details);
    }
  }

  @override
  Future<List<UrlMedio>> firmarMedio(List<String> idsElemento) async {
    try {
      final respuesta = await _invokeConTiempo(
        funcionFirmarMedio,
        {'elemento_ids': idsElemento},
      );
      final datos = respuesta.data;
      final medios = datos is Map ? datos['medios'] : null;
      if (medios is! List) return const [];
      return [for (final medio in medios) ?UrlMedio.desdeJson(medio)];
    } on TimeoutException {
      throw const ErrorFuncionesApi(
        estado: 408,
        detalles: {
          'codigo': 'tiempo_agotado',
          'mensaje': 'La firma de medios tardó demasiado.',
        },
      );
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
