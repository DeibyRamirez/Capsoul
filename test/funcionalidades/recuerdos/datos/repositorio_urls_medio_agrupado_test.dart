import 'package:capsoul/funcionalidades/recuerdos/datos/repositorio_urls_medio_agrupado.dart';
import 'package:capsoul/funcionalidades/recuerdos/dominio/enlace_medio.dart';
import 'package:capsoul/funcionalidades/recuerdos/dominio/url_medio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final inicio = DateTime.utc(2026, 10, 3, 18);
  var ahora = inicio;
  late List<List<String>> llamadas;
  late RepositorioUrlsMedioAgrupado repositorio;
  Object? fallo;
  var firma = 0;

  UrlMedio medio(String id) {
    firma++;
    return UrlMedio(
      idRecuerdo: id,
      publicId: 'capsoul/$id',
      original: EnlaceFirmado(
        url: 'https://api.cloudinary.com/$id/original/$firma',
        expiraEn: ahora.add(const Duration(hours: 24)),
      ),
      miniatura: id.startsWith('audio')
          ? null
          : EnlaceFirmado(
              url: 'https://api.cloudinary.com/$id/miniatura/$firma',
              expiraEn: ahora.add(const Duration(days: 7)),
            ),
    );
  }

  Future<String?> pedir(String id, VarianteMedio variante) =>
      repositorio.enlace(idRecuerdo: id, publicId: 'capsoul/$id', variante: variante);

  setUp(() {
    ahora = inicio;
    llamadas = [];
    fallo = null;
    firma = 0;
    repositorio = RepositorioUrlsMedioAgrupado(
      reloj: () => ahora,
      solicitar: (ids) async {
        llamadas.add(ids);
        final error = fallo;
        if (error != null) throw error;
        return [for (final id in ids) if (id != 'nota') medio(id)];
      },
    );
  });

  test('junta en una llamada los ids pedidos en el mismo ciclo', () async {
    final resultados = await Future.wait([
      pedir('a', VarianteMedio.miniatura),
      pedir('b', VarianteMedio.miniatura),
      pedir('a', VarianteMedio.original),
      pedir('nota', VarianteMedio.original),
    ]);

    expect(llamadas, [
      ['a', 'b', 'nota'],
    ]);
    expect(resultados, [
      'https://api.cloudinary.com/a/miniatura/1',
      'https://api.cloudinary.com/b/miniatura/2',
      'https://api.cloudinary.com/a/original/1',
      null,
    ]);
  });

  test('reutiliza los enlaces vigentes guardados por public_id', () async {
    await pedir('a', VarianteMedio.miniatura);
    expect(repositorio.cache.vigente('capsoul/a', VarianteMedio.original), isNotNull);

    // Ambas variantes quedaron guardadas: no hay otra llamada.
    expect(await pedir('a', VarianteMedio.original), endsWith('/original/1'));
    expect(await pedir('a', VarianteMedio.miniatura), endsWith('/miniatura/1'));
    expect(llamadas, hasLength(1));
  });

  test('pide de nuevo solo cuando el enlace está por vencer (margen 5 min)', () async {
    await pedir('a', VarianteMedio.original);

    ahora = inicio.add(const Duration(hours: 23, minutes: 54));
    await pedir('a', VarianteMedio.original);
    expect(llamadas, hasLength(1));

    ahora = inicio.add(const Duration(hours: 23, minutes: 55));
    expect(await pedir('a', VarianteMedio.original), endsWith('/original/2'));
    expect(llamadas, hasLength(2));
  });

  test('la miniatura (7 días) sigue sirviendo cuando el original (24 h) venció',
      () async {
    await pedir('a', VarianteMedio.miniatura);
    ahora = inicio.add(const Duration(days: 3));

    expect(await pedir('a', VarianteMedio.miniatura), endsWith('/miniatura/1'));
    expect(llamadas, hasLength(1));
    expect(await pedir('a', VarianteMedio.original), endsWith('/original/2'));
    expect(llamadas, hasLength(2));
  });

  test('el audio no tiene miniatura', () async {
    expect(await pedir('audio1', VarianteMedio.miniatura), isNull);
    expect(await pedir('audio1', VarianteMedio.original), isNotNull);
    expect(llamadas, hasLength(1));
  });

  test('parte los lotes grandes en grupos de 60', () async {
    await Future.wait([
      for (var i = 0; i < 61; i++) pedir('id-$i', VarianteMedio.miniatura),
    ]);
    expect(llamadas.map((l) => l.length), [60, 1]);
  });

  test('si la función falla devuelve null y no guarda nada', () async {
    fallo = Exception('sin red');
    expect(await pedir('a', VarianteMedio.miniatura), isNull);
    expect(repositorio.cache.cantidad, 0);
    fallo = null;
    expect(await pedir('a', VarianteMedio.miniatura), isNotNull);
    expect(llamadas, hasLength(2));
  });
}
