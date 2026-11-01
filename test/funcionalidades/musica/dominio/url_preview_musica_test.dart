import 'package:capsoul/funcionalidades/musica/dominio/url_preview_musica.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('acepta HTTPS de CDN Deezer', () {
    expect(
      urlPreviewConfiable('https://cdns-preview.dzcdn.net/stream/x.mp3'),
      isTrue,
    );
  });

  test('rechaza HTTP y localhost', () {
    expect(urlPreviewConfiable('http://127.0.0.1/preview.mp3'), isFalse);
    expect(urlPreviewConfiable('http://localhost/x.mp3'), isFalse);
    expect(urlPreviewConfiable('https://127.0.0.1/x.mp3'), isFalse);
    expect(urlPreviewConfiable('https://localhost/x.mp3'), isFalse);
  });

  test('rechaza vacío o mal formado', () {
    expect(urlPreviewConfiable(null), isFalse);
    expect(urlPreviewConfiable(''), isFalse);
    expect(urlPreviewConfiable('not-a-url'), isFalse);
  });
}
