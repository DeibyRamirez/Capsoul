import 'package:capsoul/funcionalidades/musica/aplicacion/intentar_cargar_preview_con_refresco.dart';
import 'package:capsoul/funcionalidades/musica/dominio/referencia_musica.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../ayudantes/falsos_musica.dart';

const _filaAntiguaConPreviewDeezer = ReferenciaMusica(
  idExterno: 'sp1',
  titulo: 'La Plena - W Sound 05',
  artista: 'W Sound',
  urlCompleta: 'https://open.spotify.com/track/sp1',
  previewUrl: 'https://cdnt-preview.dzcdn.net/api/1/1/vencido.mp3',
  enlaceDeezer: 'https://www.deezer.com/track/42',
);

void main() {
  group('debePedirPreviewFresco', () {
    test('pista de Deezer sin URL: pide /track/<id>', () {
      expect(debePedirPreviewFresco(pistaDeezerPrueba(preview: null)), isTrue);
    });

    test('pista de Deezer con URL en memoria: la ignora y pide otra', () {
      expect(debePedirPreviewFresco(pistaDeezerPrueba()), isTrue);
    });

    test('fila antigua con preview de Deezer guardado: lo ignora', () {
      expect(debePedirPreviewFresco(_filaAntiguaConPreviewDeezer), isTrue);
    });

    test('fila antigua con preview de Spotify y sin id de Deezer: lo usa', () {
      const antigua = ReferenciaMusica(
        idExterno: 'sp2',
        titulo: 'T',
        artista: 'A',
        urlCompleta: 'https://open.spotify.com/track/sp2',
        previewUrl: 'https://p.scdn.co/mp3-preview/abc',
        previewProveedor: ProveedorPreviewMusica.spotify,
      );
      expect(debePedirPreviewFresco(antigua), isFalse);
    });
  });

  group('convienePersistirPreview', () {
    test('nunca guarda una URL de Deezer', () {
      expect(convienePersistirPreview(pistaDeezerPrueba()), isFalse);
    });

    test('fila antigua refrescada con URL de Deezer: no se guarda', () {
      final refrescada = _filaAntiguaConPreviewDeezer.copiarConPreview(
        previewUrl: 'https://cdnt-preview.dzcdn.net/api/1/1/nuevo.mp3',
        previewProveedor: ProveedorPreviewMusica.deezer,
      );
      expect(convienePersistirPreview(refrescada), isFalse);
    });

    test('fila antigua refrescada sin proveedor pero con URL dzcdn: no', () {
      final refrescada = _filaAntiguaConPreviewDeezer.copiarConPreview(
        previewUrl: 'https://cdnt-preview.dzcdn.net/api/1/1/nuevo.mp3',
      );
      expect(convienePersistirPreview(refrescada), isFalse);
    });
  });
}
