import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../nucleo/infraestructura/cliente_funciones_api.dart';
import '../dominio/cache_enlaces_medio.dart';
import '../dominio/enlace_medio.dart';
import '../dominio/repositorio_urls_medio.dart';
import '../dominio/url_medio.dart';

typedef SolicitarUrlsMedio = Future<List<UrlMedio>> Function(List<String> ids);

class RepositorioUrlsMedioAgrupado implements RepositorioUrlsMedio {
  RepositorioUrlsMedioAgrupado({
    required SolicitarUrlsMedio solicitar,
    DateTime Function()? reloj,
    CacheEnlacesMedio? cache,
  })  : _solicitar = solicitar,
        cache = cache ?? CacheEnlacesMedio(reloj: reloj);

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

Future<List<UrlMedio>> solicitarUrlsMedio(
  ClienteFuncionesApi funciones,
  List<String> ids,
) =>
    funciones.firmarMedio(ids);
