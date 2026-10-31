import 'package:capsoul/funcionalidades/musica/aplicacion/abridor_enlaces_musica.dart';
import 'package:capsoul/funcionalidades/musica/dominio/referencia_musica.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../ayudantes/falsos_musica.dart';

void main() {
  final abiertos = <Uri>[];
  setUp(abiertos.clear);

  AbridorEnlacesMusica abridor({bool hayAppDeezer = true}) =>
      AbridorEnlacesMusica(
        puedeAbrir: (uri) async => uri.scheme != 'deezer' || hayAppDeezer,
        abrir: (uri) async {
          abiertos.add(uri);
          return true;
        },
      );

  test('Abrir en Deezer usa el deep link si la app está instalada', () async {
    final ok = await abridor().abrirEnDeezer(pistaDeezerPrueba(id: '5'));
    expect(ok, isTrue);
    expect(abiertos.single.toString(), 'deezer://www.deezer.com/track/5');
  });

  test('sin app de Deezer abre el enlace web del track', () async {
    await abridor(hayAppDeezer: false).abrirEnDeezer(pistaDeezerPrueba(id: '5'));
    expect(abiertos.single.toString(), 'https://www.deezer.com/track/5');
  });

  test('si el deep link falla al abrir, cae al enlace web', () async {
    final abridorQueFalla = AbridorEnlacesMusica(
      puedeAbrir: (_) async => true,
      abrir: (uri) async {
        abiertos.add(uri);
        return uri.scheme != 'deezer';
      },
    );
    final ok = await abridorQueFalla.abrirEnDeezer(pistaDeezerPrueba(id: '5'));
    expect(ok, isTrue);
    expect(abiertos.last.toString(), 'https://www.deezer.com/track/5');
  });

  test('Spotify abre una búsqueda simple para pistas de Deezer', () async {
    await abridor().abrirEnSpotify(
      pistaDeezerPrueba(titulo: 'La Plena', artista: 'Beéle'),
    );
    expect(abiertos.single.host, 'open.spotify.com');
    expect(Uri.decodeComponent(abiertos.single.path), '/search/Beéle La Plena');
  });

  test('YouTube abre results?search_query=', () async {
    await abridor().abrirEnYoutube(
      pistaDeezerPrueba(titulo: 'La Plena', artista: 'Beéle'),
    );
    final uri = abiertos.single;
    expect(uri.host, 'www.youtube.com');
    expect(uri.path, '/results');
    expect(uri.queryParameters['search_query'], 'Beéle La Plena');
  });

  test('error del lanzador devuelve false', () async {
    final roto = AbridorEnlacesMusica(
      puedeAbrir: (_) async => false,
      abrir: (_) async => throw Exception('sin navegador'),
    );
    expect(await roto.abrirEnYoutube(pistaDeezerPrueba()), isFalse);
  });

  test('enlaceDeezerParaReferencia usa el id del enlace guardado', () {
    const ref = ReferenciaMusica(
      idExterno: '1',
      titulo: 'T',
      artista: 'A',
      urlCompleta: 'https://open.spotify.com/track/1',
      enlaceDeezer: 'https://www.deezer.com/track/99',
    );
    expect(
      enlaceDeezerParaReferencia(ref).toString(),
      'https://www.deezer.com/track/99',
    );
  });

  test('enlaceDeezerParaReferencia busca si no hay id', () {
    const ref = ReferenciaMusica(
      idExterno: '1',
      titulo: 'La Plena',
      artista: 'Beéle',
      urlCompleta: 'https://open.spotify.com/track/1',
    );
    final uri = enlaceDeezerParaReferencia(ref);
    expect(uri.host, 'www.deezer.com');
    expect(uri.path, startsWith('/search/'));
  });

  test('enlaceBusquedaYoutubeMusic usa music.youtube.com', () {
    final uri = enlaceBusquedaYoutubeMusic(titulo: 'La Plena', artista: 'Beéle');
    expect(uri.host, 'music.youtube.com');
    expect(uri.queryParameters['q'], contains('Beéle'));
  });

  test('previewProveedorEfectivo infiere deezer por host dzcdn', () {
    const ref = ReferenciaMusica(
      idExterno: '1',
      titulo: 'T',
      artista: 'A',
      urlCompleta: 'https://open.spotify.com/track/1',
      previewUrl: 'https://cdns-preview.dzcdn.com/stream/x.mp3',
    );
    expect(ref.previewProveedorEfectivo, ProveedorPreviewMusica.deezer);
  });
}
