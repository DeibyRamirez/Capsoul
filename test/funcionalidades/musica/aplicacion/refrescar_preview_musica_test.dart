import 'package:capsoul/funcionalidades/musica/aplicacion/refrescar_preview_musica.dart';
import 'package:capsoul/funcionalidades/musica/dominio/referencia_musica.dart';
import 'package:capsoul/funcionalidades/musica/dominio/repositorio_catalogo_musica.dart';
import 'package:flutter_test/flutter_test.dart';

class _CatalogoFalso implements RepositorioCatalogoMusica {
  _CatalogoFalso(this.resultados);

  final List<ReferenciaMusica> resultados;

  @override
  Future<List<ReferenciaMusica>> buscar(
    String consulta, {
    int limite = 20,
    String mercado = 'CO',
  }) async {
    return resultados.take(limite).toList();
  }
}

void main() {
  test('refrescarPreview devuelve pista con mismo idExterno y nuevo preview', () async {
    const actual = ReferenciaMusica(
      idExterno: 'spotify-1',
      titulo: 'La Plena',
      artista: 'Artista',
      urlCompleta: 'https://open.spotify.com/track/spotify-1',
      previewUrl: 'https://cdns-preview.dzcdn.net/viejo.mp3',
    );
    final catalogo = _CatalogoFalso([
      const ReferenciaMusica(
        idExterno: 'otro',
        titulo: 'Otra',
        artista: 'X',
        urlCompleta: 'https://open.spotify.com/track/otro',
        previewUrl: 'https://nuevo.mp3',
      ),
      ReferenciaMusica(
        idExterno: 'spotify-1',
        titulo: 'La Plena',
        artista: 'Artista',
        urlCompleta: 'https://open.spotify.com/track/spotify-1',
        previewUrl: 'https://cdns-preview.dzcdn.net/nuevo.mp3',
        previewProveedor: ProveedorPreviewMusica.deezer,
        enlaceDeezer: 'https://www.deezer.com/track/99',
      ),
    ]);

    final resultado = await refrescarPreview(actual, catalogo);
    expect(resultado, isNotNull);
    expect(resultado!.idExterno, 'spotify-1');
    expect(resultado.previewUrl, contains('nuevo.mp3'));
    expect(resultado.previewProveedor, ProveedorPreviewMusica.deezer);
    expect(resultado.enlaceDeezer, contains('deezer.com'));
  });

  test('refrescarPreview devuelve null si no hay coincidencia con preview', () async {
    const actual = ReferenciaMusica(
      idExterno: 'a',
      titulo: 'T',
      artista: 'B',
      urlCompleta: 'https://open.spotify.com/track/a',
      previewUrl: 'https://viejo.mp3',
    );
    final catalogo = _CatalogoFalso([
      const ReferenciaMusica(
        idExterno: 'a',
        titulo: 'T',
        artista: 'B',
        urlCompleta: 'https://open.spotify.com/track/a',
      ),
    ]);
    expect(await refrescarPreview(actual, catalogo), isNull);
  });
}
