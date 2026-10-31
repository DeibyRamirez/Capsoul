import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../dominio/fallo_musica.dart';
import '../dominio/pista_deezer.dart';
import '../dominio/referencia_musica.dart';
import '../dominio/repositorio_catalogo_musica.dart';

/// Catálogo con la API pública de Deezer (sin clave).
///
/// - `GET https://api.deezer.com/search?q=...&limit=...`
/// - `GET https://api.deezer.com/track/<id>` (preview fresco al reproducir)
///
/// Deezer responde 200 con `{"error": {...}}` cuando algo falla; se traduce
/// a [FalloMusica]. El cliente HTTP se inyecta para poder simularlo.
class RepositorioMusicaDeezer implements RepositorioCatalogoMusica {
  RepositorioMusicaDeezer(
    this._cliente, {
    Uri? base,
    this.tiempoMaximo = const Duration(seconds: 8),
  }) : _base = base ?? Uri.https('api.deezer.com', '/');

  final http.Client _cliente;
  final Uri _base;
  final Duration tiempoMaximo;

  /// Código de Deezer para "no hay datos" (pista inexistente).
  static const _codigoSinDatos = 800;

  /// Código de Deezer para cuota superada (50 solicitudes / 5 s).
  static const _codigoCuota = 4;

  @override
  Future<List<ReferenciaMusica>> buscar(
    String consulta, {
    int limite = 25,
    String mercado = 'CO',
  }) async {
    final texto = consulta.trim();
    if (texto.isEmpty) return const [];
    final datos = await _pedir('/search', {
      'q': texto,
      'limit': '${limite.clamp(1, 50)}',
    });
    final lista = datos['data'];
    if (lista is! List) {
      throw const FalloMusica(TipoFalloMusica.respuestaInvalida);
    }
    return [
      for (final fila in lista)
        ?PistaDeezer.intentarDesdeJson(fila)?.aReferencia(),
    ];
  }

  @override
  Future<ReferenciaMusica?> obtenerPorId(String idExterno) async {
    final id = idExterno.trim();
    if (!RegExp(r'^\d+$').hasMatch(id)) return null;
    try {
      final datos = await _pedir('/track/$id');
      return PistaDeezer.intentarDesdeJson(datos)?.aReferencia();
    } on FalloMusica catch (fallo) {
      if (fallo.tipo == TipoFalloMusica.noEncontrada) return null;
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _pedir(
    String ruta, [
    Map<String, String>? parametros,
  ]) async {
    final uri = _base.replace(path: ruta, queryParameters: parametros);
    final http.Response respuesta;
    try {
      respuesta = await _cliente
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(tiempoMaximo);
    } on TimeoutException {
      throw const FalloMusica(TipoFalloMusica.tiempoAgotado);
    } catch (_) {
      throw const FalloMusica(TipoFalloMusica.sinConexion);
    }
    if (respuesta.statusCode == 429) {
      throw const FalloMusica(TipoFalloMusica.limiteSolicitudes);
    }
    if (respuesta.statusCode < 200 || respuesta.statusCode >= 300) {
      throw const FalloMusica(TipoFalloMusica.servicio);
    }
    final Object? datos;
    try {
      datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
    } on FormatException {
      throw const FalloMusica(TipoFalloMusica.respuestaInvalida);
    }
    if (datos is! Map<String, dynamic>) {
      throw const FalloMusica(TipoFalloMusica.respuestaInvalida);
    }
    final error = datos['error'];
    if (error is Map) {
      throw FalloMusica(switch (error['code']) {
        _codigoSinDatos => TipoFalloMusica.noEncontrada,
        _codigoCuota => TipoFalloMusica.limiteSolicitudes,
        _ => TipoFalloMusica.servicio,
      });
    }
    return datos;
  }
}
