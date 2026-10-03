import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../dominio/fallo_medios.dart';
import '../dominio/tipo_elemento.dart';

/// Firma de Cloudinary que devuelve la Edge Function `firmar-subida`.
class FirmaSubida {
  const FirmaSubida({
    required this.urlSubida,
    required this.parametros,
  });

  /// `https://api.cloudinary.com/v1_1/<cloud>/<image|video>/upload`.
  final String urlSubida;

  /// Campos del formulario de subida tal cual se firmaron (incluye
  /// `api_key`, `timestamp`, `signature`, `public_id`, `type`, `eager`).
  final Map<String, String> parametros;

  /// Falla cerrado ante una respuesta incompleta.
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
    for (final requerido in const ['api_key', 'timestamp', 'signature', 'public_id']) {
      if (!campos.containsKey(requerido)) return null;
    }
    return FirmaSubida(urlSubida: url, parametros: Map.unmodifiable(campos));
  }
}

/// Pide al servidor una firma de subida para un medio.
abstract interface class ClienteFirmaSubida {
  Future<FirmaSubida> solicitarFirma({
    required TipoElemento tipo,
    required int bytes,
    Duration? duracion,
    String? formato,
  });
}

/// [ClienteFirmaSubida] que invoca la Edge Function `firmar-subida` con el
/// JWT de la sesión (lo agrega `supabase_flutter`).
class ClienteFirmaSubidaSupabase implements ClienteFirmaSubida {
  ClienteFirmaSubidaSupabase({SupabaseClient? cliente})
      : _clienteInyectado = cliente;

  static const String nombreFuncion = 'firmar-subida';

  final SupabaseClient? _clienteInyectado;

  SupabaseClient get _cliente => _clienteInyectado ?? Supabase.instance.client;

  @override
  Future<FirmaSubida> solicitarFirma({
    required TipoElemento tipo,
    required int bytes,
    Duration? duracion,
    String? formato,
  }) async {
    try {
      final respuesta = await _cliente.functions.invoke(
        nombreFuncion,
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
        debugPrint('Capsoul: respuesta inválida de firmar-subida');
        throw const FalloMedios.subidaFallida();
      }
      return firma;
    } on FunctionException catch (error) {
      throw traducirErrorFuncion(error.status, error.details);
    } on SocketException {
      throw const FalloMedios.sinRed();
    } on TimeoutException {
      throw const FalloMedios.sinRed();
    }
  }

  /// Traduce el código HTTP de la función (y su `codigo` JSON) a un fallo.
  @visibleForTesting
  static FalloMedios traducirErrorFuncion(int estado, Object? detalles) {
    final codigo = detalles is Map ? detalles['codigo'] : null;
    if (codigo == 'cuota_excedida') return const FalloMedios.cuotaExcedida();
    if (detalles is Map && detalles['mensaje'] is String && estado == 422) {
      return FalloMedios(
        codigo is String ? codigo : FalloMedios.codigoSubidaFallida,
        detalles['mensaje'] as String,
      );
    }
    return switch (estado) {
      // Función no desplegada todavía (o ruta inexistente).
      404 => const FalloMedios.subidaNoDisponible(),
      _ => const FalloMedios.subidaFallida(),
    };
  }
}
