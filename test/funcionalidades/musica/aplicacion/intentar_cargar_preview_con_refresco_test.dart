import 'package:capsoul/funcionalidades/musica/aplicacion/intentar_cargar_preview_con_refresco.dart';
import 'package:capsoul/funcionalidades/musica/dominio/referencia_musica.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';

import '../../../ayudantes/falsos_musica.dart';

void main() {
  test('preview localhost pide Deezer antes de cargar', () async {
    final fresca = pistaDeezerPrueba(
      id: '42',
      preview: 'https://cdnt-preview.dzcdn.net/ok.mp3',
    );
    final catalogo = CatalogoMusicaFalso(porId: {'42': fresca});
    const antigua = ReferenciaMusica(
      idExterno: 'sp1',
      titulo: 'T',
      artista: 'A',
      urlCompleta: 'https://open.spotify.com/track/sp1',
      previewUrl: 'http://127.0.0.1/preview.mp3',
      enlaceDeezer: 'https://www.deezer.com/track/42',
    );

    final reproductor = AudioPlayer();
    addTearDown(reproductor.dispose);

    try {
      await intentarCargarPreviewConRefresco(
        reproductor,
        antigua,
        catalogo,
      );
    } catch (_) {
      // En CI puede fallar la descarga real del MP3; basta comprobar el catálogo.
    }

    expect(catalogo.idsPedidos, ['42']);
  });
}
