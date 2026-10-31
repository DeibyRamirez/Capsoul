import 'package:capsoul/funcionalidades/musica/aplicacion/reproducir_preview_musica.dart';
import 'package:capsoul/funcionalidades/musica/dominio/referencia_musica.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';

import '../../../ayudantes/falsos_musica.dart';

void main() {
  test('el preview usa la URL https directa, sin headers (sin proxy local)', () {
    final fuente = fuenteAudioPreview(
      pistaDeezerPrueba(preview: '  https://cdnt-preview.dzcdn.net/api/1/1/x.mp3 '),
    );
    expect(fuente, isA<UriAudioSource>());
    final uri = (fuente as UriAudioSource).uri;
    expect(uri.toString(), 'https://cdnt-preview.dzcdn.net/api/1/1/x.mp3');
    expect(uri.scheme, 'https');
    expect(fuente.headers, isNull);
  });

  test('filas antiguas de Spotify tampoco usan headers', () {
    const ref = ReferenciaMusica(
      idExterno: 't1',
      titulo: 'T',
      artista: 'A',
      urlCompleta: 'https://open.spotify.com/track/t1',
      previewUrl: 'https://p.scdn.co/mp3-preview/x',
    );
    final fuente = fuenteAudioPreview(ref) as UriAudioSource;
    expect(fuente.headers, isNull);
    expect(fuente.uri.host, 'p.scdn.co');
  });
}
