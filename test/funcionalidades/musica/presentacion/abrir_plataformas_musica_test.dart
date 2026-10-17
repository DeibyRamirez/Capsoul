import 'package:capsoul/funcionalidades/musica/dominio/referencia_musica.dart';
import 'package:capsoul/funcionalidades/musica/presentacion/abrir_plataformas_musica.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('enlaceBusquedaYoutubeMusic usa music.youtube.com', () {
    final uri = enlaceBusquedaYoutubeMusic(
      titulo: 'La Plena',
      artista: 'Beéle',
    );
    expect(uri.host, 'music.youtube.com');
    expect(uri.path, '/search');
    expect(uri.queryParameters['q'], contains('Beéle'));
  });

  test('enlaceDeezerParaReferencia usa enlace guardado', () {
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

  test('enlaceDeezerParaReferencia busca si no hay enlace directo', () {
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
