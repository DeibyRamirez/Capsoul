import 'package:capsoul/funcionalidades/musica/dominio/referencia_musica.dart';
import 'package:capsoul/funcionalidades/recuerdos/datos/mapeo_recuerdos.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mapea fila de elementos a ReferenciaMusica', () {
    final recuerdo = recuerdoDesdeFila({
      'id': 'e1',
      'propietario_id': 'u1',
      'tipo': 'musica',
      'fecha_recuerdo': '2026-10-01',
      'creado_en': '2026-10-01T12:00:00Z',
      'musica_proveedor': 'spotify',
      'musica_id_externo': 't1',
      'musica_titulo': 'Canción',
      'musica_artista': 'Banda',
      'musica_url_completa': 'https://open.spotify.com/track/t1',
      'musica_preview_url': 'https://preview.mp3',
    });
    expect(recuerdo, isNotNull);
    expect(recuerdo!.musica?.etiquetaCorta, 'Banda — Canción');
  });

  test('desdeJsonApi ignora entradas incompletas', () {
    expect(
      ReferenciaMusica.desdeJsonApi({'idExterno': 'x'}),
      isNull,
    );
    final ok = ReferenciaMusica.desdeJsonApi({
      'idExterno': 'x',
      'titulo': 'T',
      'artista': 'A',
      'urlCompleta': 'https://open.spotify.com/track/x',
    });
    expect(ok?.titulo, 'T');
    expect(ok?.tienePreview, isFalse);
  });

  test('desdeJsonApi parsea previewProveedor deezer', () {
    final ref = ReferenciaMusica.desdeJsonApi({
      'idExterno': 'x',
      'titulo': 'T',
      'artista': 'A',
      'urlCompleta': 'https://open.spotify.com/track/x',
      'previewUrl': 'https://cdns-preview.dzcdn.com/stream/x.mp3',
      'previewProveedor': 'deezer',
      'enlaceDeezer': 'https://www.deezer.com/track/42',
    });
    expect(ref?.previewProveedor, ProveedorPreviewMusica.deezer);
    expect(ref?.etiquetaPreview, 'Vista previa (Deezer)');
    expect(ref?.enlaceDeezer, 'https://www.deezer.com/track/42');
  });

  test('desdeFilaBd lee musica_enlace_deezer', () {
    final ref = ReferenciaMusica.desdeFilaBd({
      'musica_id_externo': 't1',
      'musica_titulo': 'Canción',
      'musica_artista': 'Banda',
      'musica_url_completa': 'https://open.spotify.com/track/t1',
      'musica_enlace_deezer': 'https://www.deezer.com/track/9',
    });
    expect(ref?.enlaceDeezer, 'https://www.deezer.com/track/9');
  });

  test('tienePreview refleja previewUrl', () {
    const conPreview = ReferenciaMusica(
      idExterno: '1',
      titulo: 'T',
      artista: 'A',
      urlCompleta: 'https://open.spotify.com/track/1',
      previewUrl: 'https://preview.mp3',
    );
    const sinPreview = ReferenciaMusica(
      idExterno: '2',
      titulo: 'T',
      artista: 'A',
      urlCompleta: 'https://open.spotify.com/track/2',
    );
    expect(conPreview.tienePreview, isTrue);
    expect(sinPreview.tienePreview, isFalse);
  });
}
