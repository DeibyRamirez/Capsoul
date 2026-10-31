import 'package:capsoul/funcionalidades/musica/dominio/pista_deezer.dart';
import 'package:capsoul/funcionalidades/musica/dominio/referencia_musica.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> jsonPista({Object? preview = 'https://cdnt-preview.dzcdn.net/x.mp3'}) => {
      'id': 3135556,
      'title': 'Harder, Better, Faster, Stronger',
      'link': 'https://www.deezer.com/track/3135556',
      'duration': 224,
      'preview': preview,
      'artist': {'id': 27, 'name': 'Daft Punk'},
      'album': {
        'title': 'Discovery',
        'cover_medium': 'https://e-cdns-images.dzcdn.net/medium.jpg',
      },
    };

void main() {
  test('fromJson lee los campos de la API de Deezer', () {
    final pista = PistaDeezer.fromJson(jsonPista());
    expect(pista.id, '3135556');
    expect(pista.titulo, 'Harder, Better, Faster, Stronger');
    expect(pista.artista, 'Daft Punk');
    expect(pista.album, 'Discovery');
    expect(pista.portadaUrl, 'https://e-cdns-images.dzcdn.net/medium.jpg');
    expect(pista.duracionSegundos, 224);
    expect(pista.tienePreview, isTrue);
    expect(pista, PistaDeezer.fromJson(jsonPista()));
  });

  test('fromJson lanza FormatException si falta el artista', () {
    final json = jsonPista()..remove('artist');
    expect(() => PistaDeezer.fromJson(json), throwsFormatException);
    expect(PistaDeezer.intentarDesdeJson(json), isNull);
    expect(PistaDeezer.intentarDesdeJson('texto'), isNull);
  });

  test('preview vacío queda como sin preview', () {
    final pista = PistaDeezer.fromJson(jsonPista(preview: ''));
    expect(pista.tienePreview, isFalse);
    final ref = pista.aReferencia();
    expect(ref.tienePreview, isFalse);
    expect(ref.puedeReproducirPreview, isTrue, reason: 'se pide por id');
  });

  test('aReferencia arma enlaces y deep link de Deezer', () {
    final ref = PistaDeezer.fromJson(jsonPista()).aReferencia();
    expect(ref.proveedor, ProveedorMusica.deezer);
    expect(ref.idPistaDeezer, '3135556');
    expect(ref.urlCompleta, 'https://www.deezer.com/track/3135556');
    expect(ref.uriProfundo, 'deezer://www.deezer.com/track/3135556');
    expect(ref.previewProveedor, ProveedorPreviewMusica.deezer);
  });

  test('aFilaBd de Deezer guarda solo metadatos, nunca la URL del preview', () {
    final fila = PistaDeezer.fromJson(jsonPista()).aReferencia().aFilaBd();
    expect(fila['musica_proveedor'], 'deezer');
    expect(fila['musica_id_externo'], '3135556');
    expect(fila['musica_preview_url'], isNull);
    expect(fila['musica_enlace_deezer'], 'https://www.deezer.com/track/3135556');
    final leida = ReferenciaMusica.desdeFilaBd(fila);
    expect(leida?.proveedor, ProveedorMusica.deezer);
    expect(leida?.tienePreview, isFalse);
    expect(leida?.puedeReproducirPreview, isTrue);
  });
}
