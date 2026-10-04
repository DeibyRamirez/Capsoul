import 'package:capsoul/funcionalidades/recuerdos/dominio/cache_enlaces_medio.dart';
import 'package:capsoul/funcionalidades/recuerdos/dominio/enlace_medio.dart';
import 'package:capsoul/funcionalidades/recuerdos/dominio/url_medio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final inicio = DateTime.utc(2026, 10, 3, 18);
  var ahora = inicio;
  late CacheEnlacesMedio cache;

  EnlaceFirmado enlace(String url, Duration vence) =>
      EnlaceFirmado(url: 'https://$url', expiraEn: inicio.add(vence));

  setUp(() {
    ahora = inicio;
    cache = CacheEnlacesMedio(reloj: () => ahora);
  });

  test('la clave es el public_id con la variante, no la URL', () {
    expect(claveMedio('capsoul/a', VarianteMedio.miniatura), 'capsoul/a|miniatura');
    expect(claveMedio('capsoul/a', VarianteMedio.original), 'capsoul/a|original');
  });

  test('reutiliza el enlace mientras falten más de 5 minutos', () {
    final original = enlace('o', const Duration(hours: 24));
    cache.guardar('capsoul/a', VarianteMedio.original, original);

    expect(cache.vigente('capsoul/a', VarianteMedio.original), original);
    ahora = inicio.add(const Duration(hours: 23, minutes: 54, seconds: 59));
    expect(cache.vigente('capsoul/a', VarianteMedio.original), original);
  });

  test('a 5 minutos o menos de caducar ya no sirve y se quita', () {
    cache.guardar(
      'capsoul/a',
      VarianteMedio.original,
      enlace('o', const Duration(hours: 24)),
    );
    ahora = inicio.add(const Duration(hours: 23, minutes: 55));
    expect(cache.vigente('capsoul/a', VarianteMedio.original), isNull);
    expect(cache.cantidad, 0);
  });

  test('cada variante tiene su propia caducidad', () {
    cache.guardarMedio(
      'capsoul/a',
      UrlMedio(
        idRecuerdo: 'r1',
        original: enlace('o', const Duration(hours: 24)),
        miniatura: enlace('m', const Duration(days: 7)),
      ),
    );
    ahora = inicio.add(const Duration(days: 2));
    expect(cache.vigente('capsoul/a', VarianteMedio.original), isNull);
    expect(cache.vigente('capsoul/a', VarianteMedio.miniatura)?.url, 'https://m');
    ahora = inicio.add(const Duration(days: 6, hours: 23, minutes: 56));
    expect(cache.vigente('capsoul/a', VarianteMedio.miniatura), isNull);
  });

  test('sin miniatura (audio) solo guarda el original', () {
    cache.guardarMedio(
      'capsoul/audio',
      UrlMedio(idRecuerdo: 'r', original: enlace('o', const Duration(hours: 24))),
    );
    expect(cache.cantidad, 1);
    expect(cache.vigente('capsoul/audio', VarianteMedio.miniatura), isNull);
  });

  test('limpiarVencidos quita solo lo vencido o por vencer', () {
    cache
      ..guardar('a', VarianteMedio.original, enlace('o', const Duration(hours: 1)))
      ..guardar('a', VarianteMedio.miniatura, enlace('m', const Duration(days: 7)));
    ahora = inicio.add(const Duration(minutes: 56));
    cache.limpiarVencidos();
    expect(cache.cantidad, 1);
    expect(cache.vigente('a', VarianteMedio.miniatura), isNotNull);
    cache.vaciar();
    expect(cache.cantidad, 0);
  });

  group('UrlMedio.desdeJson', () {
    test('lee las dos caducidades y el public_id', () {
      final medio = UrlMedio.desdeJson({
        'id': 'r1',
        'public_id': 'capsoul/a',
        'url': 'https://api.cloudinary.com/o',
        'expira_original': '2026-10-04T18:00:00.000Z',
        'url_miniatura': 'https://api.cloudinary.com/m',
        'expira_miniatura': '2026-10-10T18:00:00.000Z',
        'expira_en': '2026-10-04T18:00:00.000Z',
      })!;
      expect(medio.publicId, 'capsoul/a');
      expect(medio.original.expiraEn, DateTime.utc(2026, 10, 4, 18));
      expect(medio.miniatura?.expiraEn, DateTime.utc(2026, 10, 10, 18));
      expect(medio.de(VarianteMedio.miniatura)?.url, 'https://api.cloudinary.com/m');
    });

    test('acepta la versión 1 (solo expira_en)', () {
      final medio = UrlMedio.desdeJson({
        'id': 'r1',
        'url': 'https://x/o',
        'url_miniatura': 'https://x/m',
        'expira_en': '2026-10-03T19:00:00.000Z',
      })!;
      expect(medio.publicId, isNull);
      expect(medio.original.expiraEn, DateTime.utc(2026, 10, 3, 19));
      expect(medio.miniatura?.expiraEn, DateTime.utc(2026, 10, 3, 19));
    });

    test('falla cerrado', () {
      expect(
        UrlMedio.desdeJson({
          'id': 'a',
          'url': 'http://inseguro',
          'expira_original': '2026-10-03T19:00:00.000Z',
        }),
        isNull,
      );
      expect(UrlMedio.desdeJson({'id': 'a', 'url': 'https://x'}), isNull);
      expect(UrlMedio.desdeJson('basura'), isNull);
      expect(
        UrlMedio.desdeJson({
          'id': 'a',
          'url': 'https://x',
          'url_miniatura': 'http://inseguro',
          'expira_original': '2026-10-03T19:00:00.000Z',
        })?.miniatura,
        isNull,
      );
    });
  });
}
