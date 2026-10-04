import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../dominio/cache_enlaces_medio.dart';
import '../dominio/enlace_medio.dart';
import '../dominio/repositorio_urls_medio.dart';
import '../dominio/url_medio.dart';

/// Pide a `firmar-medio` las URLs de varios recuerdos de una vez.
typedef SolicitarUrlsMedio = Future<List<UrlMedio>> Function(List<String> ids);

/// [RepositorioUrlsMedio] que reutiliza los enlaces vigentes de
/// [CacheEnlacesMedio] (por `public_id` y variante) y, para los que faltan o
/// están por vencer, junta en una sola llamada los ids pedidos en el mismo
/// ciclo (una rejilla entera).
class RepositorioUrlsMedioAgrupado implements RepositorioUrlsMedio {
  RepositorioUrlsMedioAgrupado({
    required this._solicitar,
    DateTime Function()? reloj,
    CacheEnlacesMedio? cache,
  }) : cache = cache ?? CacheEnlacesMedio(reloj: reloj);

  /// Máximo de ids por llamada (igual que la Edge Function).
  static const int maximoPorLlamada = 60;

  final SolicitarUrlsMedio _solicitar;
  final CacheEnlacesMedio cache;
  final Map<String, Completer<UrlMedio?>> _pendientes = {};
  final Map<String, String> _publicIdsPendientes = {};
  bool _programado = false;

  @override
  Future<String?> enlace({
    required String idRecuerdo,
    required String publicId,
    required VarianteMedio variante,
  }) {
    final guardado = cache.vigente(publicId, variante);
    if (guardado != null) return SynchronousFuture(guardado.url);
    return _pedir(idRecuerdo, publicId)
        .then((medio) => medio?.de(variante)?.url);
  }

  Future<UrlMedio?> _pedir(String idRecuerdo, String publicId) {
    final pendiente = _pendientes[idRecuerdo];
    if (pendiente != null) return pendiente.future;
    final completer = Completer<UrlMedio?>();
    _pendientes[idRecuerdo] = completer;
    _publicIdsPendientes[idRecuerdo] = publicId;
    if (!_programado) {
      _programado = true;
      // Timer de 0: corre después de que el frame actual pida todas sus
      // miniaturas.
      Timer(Duration.zero, _enviar);
    }
    return completer.future;
  }

  Future<void> _enviar() async {
    _programado = false;
    final lote = Map.of(_pendientes);
    final publicIds = Map.of(_publicIdsPendientes);
    _pendientes.clear();
    _publicIdsPendientes.clear();
    final ids = lote.keys.toList();
    for (var inicio = 0; inicio < ids.length; inicio += maximoPorLlamada) {
      final parte = ids.sublist(
        inicio,
        (inicio + maximoPorLlamada).clamp(0, ids.length),
      );
      List<UrlMedio> medios;
      try {
        medios = await _solicitar(parte);
      } catch (error) {
        debugPrint('Capsoul: firmar-medio falló: $error');
        medios = const [];
      }
      final porId = {for (final medio in medios) medio.idRecuerdo: medio};
      for (final id in parte) {
        final medio = porId[id];
        final publicId = medio?.publicId ?? publicIds[id];
        if (medio != null && publicId != null) {
          cache.guardarMedio(publicId, medio);
        }
        lote[id]?.complete(medio);
      }
    }
  }
}

/// Llama a la Edge Function `firmar-medio` con el JWT de la sesión.
Future<List<UrlMedio>> solicitarUrlsMedioSupabase(
  List<String> ids, {
  SupabaseClient? cliente,
}) async {
  final respuesta = await (cliente ?? Supabase.instance.client)
      .functions
      .invoke('firmar-medio', body: {'elemento_ids': ids});
  final datos = respuesta.data;
  final medios = datos is Map ? datos['medios'] : null;
  if (medios is! List) return const [];
  return [for (final medio in medios) ?UrlMedio.desdeJson(medio)];
}
