import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../dominio/repositorio_urls_medio.dart';
import '../dominio/url_medio.dart';

/// Pide a `firmar-medio` las URLs de varios recuerdos de una vez.
typedef SolicitarUrlsMedio = Future<List<UrlMedio>> Function(List<String> ids);

/// [RepositorioUrlsMedio] que junta en una sola llamada los ids pedidos en
/// el mismo ciclo (una rejilla entera) y guarda las URLs hasta poco antes de
/// que caduquen.
class RepositorioUrlsMedioAgrupado implements RepositorioUrlsMedio {
  RepositorioUrlsMedioAgrupado({
    required this._solicitar,
    DateTime Function()? reloj,
  }) : _reloj = reloj ?? DateTime.now;

  /// Máximo de ids por llamada (igual que la Edge Function).
  static const int maximoPorLlamada = 60;

  final SolicitarUrlsMedio _solicitar;
  final DateTime Function() _reloj;
  final Map<String, UrlMedio> _cache = {};
  final Map<String, Completer<UrlMedio?>> _pendientes = {};
  bool _programado = false;

  @override
  Future<UrlMedio?> obtener(String idRecuerdo) {
    final guardada = _cache[idRecuerdo];
    if (guardada != null && guardada.vigente(_reloj())) {
      return SynchronousFuture(guardada);
    }
    final pendiente = _pendientes[idRecuerdo];
    if (pendiente != null) return pendiente.future;
    final completer = Completer<UrlMedio?>();
    _pendientes[idRecuerdo] = completer;
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
    _pendientes.clear();
    final ids = lote.keys.toList();
    for (var inicio = 0; inicio < ids.length; inicio += maximoPorLlamada) {
      final parte = ids.sublist(
        inicio,
        (inicio + maximoPorLlamada).clamp(0, ids.length),
      );
      List<UrlMedio> urls;
      try {
        urls = await _solicitar(parte);
      } catch (error) {
        debugPrint('Capsoul: firmar-medio falló: $error');
        urls = const [];
      }
      for (final url in urls) {
        _cache[url.idRecuerdo] = url;
      }
      for (final id in parte) {
        lote[id]?.complete(_cache[id]);
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
