import 'package:capsoul/funcionalidades/musica/aplicacion/reproducir_preview_musica.dart';
import 'package:capsoul/funcionalidades/musica/dominio/referencia_musica.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ReferenciaMusica refConPreview(String url) => ReferenciaMusica(
        idExterno: 't1',
        titulo: 'T',
        artista: 'A',
        urlCompleta: 'https://open.spotify.com/track/t1',
        previewUrl: url,
      );

  test('cabecerasPreview incluye Referer para dzcdn', () {
    final ref = refConPreview('https://cdns-preview.dzcdn.net/stream/x.mp3');
    final headers = cabecerasPreview(ref);
    expect(headers['Referer'], 'https://www.deezer.com/');
    expect(headers['User-Agent'], isNotEmpty);
    expect(headers['Accept'], '*/*');
  });

  test('cabecerasPreview incluye Referer para scdn', () {
    final ref = refConPreview('https://p.scdn.co/mp3-preview/x');
    final headers = cabecerasPreview(ref);
    expect(headers['Referer'], 'https://open.spotify.com/');
  });

  test('cabecerasPreview sin Referer en host genérico', () {
    final ref = refConPreview('https://example.com/preview.mp3');
    final headers = cabecerasPreview(ref);
    expect(headers.containsKey('Referer'), isFalse);
    expect(headers['User-Agent'], isNotEmpty);
  });
}
