import 'package:capsoul/funcionalidades/musica/aplicacion/refrescar_preview_musica.dart';
import 'package:capsoul/funcionalidades/musica/dominio/referencia_musica.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../ayudantes/falsos_musica.dart';

void main() {
  test('pista de Deezer guardada: vuelve a pedir /track/<id>', () async {
    final fresca = pistaDeezerPrueba(preview: 'https://dzcdn.net/nuevo.mp3');
    final catalogo = CatalogoMusicaFalso(porId: {'3135556': fresca});
    final guardada = pistaDeezerPrueba(preview: null);

    final resultado = await refrescarPreview(guardada, catalogo);

    expect(catalogo.idsPedidos, ['3135556']);
    expect(catalogo.consultas, isEmpty);
    expect(resultado?.previewUrl, 'https://dzcdn.net/nuevo.mp3');
  });

  test('fila antigua de Spotify con enlace de Deezer usa el id', () async {
    final catalogo = CatalogoMusicaFalso(
      porId: {'42': pistaDeezerPrueba(id: '42', preview: 'https://dzcdn.net/42.mp3')},
    );
    const antigua = ReferenciaMusica(
      idExterno: 'sp1',
      titulo: 'T',
      artista: 'A',
      urlCompleta: 'https://open.spotify.com/track/sp1',
      previewUrl: 'https://dzcdn.net/viejo.mp3',
      enlaceDeezer: 'https://www.deezer.com/track/42',
    );

    final resultado = await refrescarPreview(antigua, catalogo);

    expect(resultado?.idExterno, 'sp1');
    expect(resultado?.proveedor, ProveedorMusica.spotify);
    expect(resultado?.previewUrl, 'https://dzcdn.net/42.mp3');
  });

  test('fila antigua sin id de Deezer busca por título', () async {
    final catalogo = CatalogoMusicaFalso(respuestas: {
      'Daft Punk One More Time': [
        pistaDeezerPrueba(id: '9', titulo: 'Otra', preview: 'https://x/otra.mp3'),
        pistaDeezerPrueba(id: '7', titulo: 'One More Time', preview: 'https://x/7.mp3'),
      ],
    });
    const antigua = ReferenciaMusica(
      idExterno: 'sp1',
      titulo: 'One More Time',
      artista: 'Daft Punk',
      urlCompleta: 'https://open.spotify.com/track/sp1',
    );

    final resultado = await refrescarPreview(antigua, catalogo);

    expect(resultado?.previewUrl, 'https://x/7.mp3');
    expect(resultado?.enlaceDeezer, 'https://www.deezer.com/track/7');
  });

  test('devuelve null si Deezer ya no tiene la pista', () async {
    final catalogo = CatalogoMusicaFalso();
    expect(await refrescarPreview(pistaDeezerPrueba(), catalogo), isNull);
  });
}
