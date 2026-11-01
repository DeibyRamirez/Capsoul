import 'dart:async';

import 'package:capsoul/funcionalidades/musica/dominio/referencia_musica.dart';
import 'package:capsoul/funcionalidades/musica/dominio/repositorio_catalogo_musica.dart';

/// Catálogo de música en memoria para pruebas.
class CatalogoMusicaFalso implements RepositorioCatalogoMusica {
  CatalogoMusicaFalso({
    Map<String, List<ReferenciaMusica>>? respuestas,
    Map<String, ReferenciaMusica>? porId,
  })  : respuestas = respuestas ?? {},
        porId = porId ?? {};

  final Map<String, List<ReferenciaMusica>> respuestas;
  final Map<String, ReferenciaMusica> porId;

  /// Si no es null, `buscar` espera este completer por consulta.
  final Map<String, Completer<List<ReferenciaMusica>>> pendientes = {};
  Object? fallo;
  final consultas = <String>[];
  final idsPedidos = <String>[];

  @override
  Future<List<ReferenciaMusica>> buscar(
    String consulta, {
    int limite = 25,
    String mercado = 'CO',
  }) async {
    consultas.add(consulta);
    final pendiente = pendientes[consulta];
    if (pendiente != null) return pendiente.future;
    final error = fallo;
    if (error != null) throw error;
    return respuestas[consulta] ?? const [];
  }

  @override
  Future<ReferenciaMusica?> obtenerPorId(String idExterno) async {
    idsPedidos.add(idExterno);
    return porId[idExterno];
  }
}

ReferenciaMusica pistaDeezerPrueba({
  String id = '3135556',
  String titulo = 'Harder, Better, Faster, Stronger',
  String artista = 'Daft Punk',
  String? preview = 'https://cdnt-preview.dzcdn.net/api/1/1/x.mp3',
}) =>
    ReferenciaMusica(
      proveedor: ProveedorMusica.deezer,
      idExterno: id,
      titulo: titulo,
      artista: artista,
      urlCompleta: 'https://www.deezer.com/track/$id',
      enlaceDeezer: 'https://www.deezer.com/track/$id',
      previewUrl: preview,
      previewProveedor: preview == null ? null : ProveedorPreviewMusica.deezer,
      uriProfundo: 'deezer://www.deezer.com/track/$id',
    );
