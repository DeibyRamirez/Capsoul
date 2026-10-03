import 'package:capsoul/funcionalidades/recuerdos/datos/repositorio_urls_medio_agrupado.dart';
import 'package:capsoul/funcionalidades/recuerdos/dominio/url_medio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  var ahora = DateTime.utc(2026, 10, 3, 18);
  late List<List<String>> llamadas;
  late RepositorioUrlsMedioAgrupado repositorio;
  Object? fallo;

  UrlMedio url(String id, {Duration vence = const Duration(hours: 1)}) =>
      UrlMedio(
        idRecuerdo: id,
        url: 'https://api.cloudinary.com/$id',
        urlMiniatura: 'https://res.cloudinary.com/$id.jpg',
        expiraEn: ahora.add(vence),
      );

  setUp(() {
    ahora = DateTime.utc(2026, 10, 3, 18);
    llamadas = [];
    fallo = null;
    repositorio = RepositorioUrlsMedioAgrupado(
      reloj: () => ahora,
      solicitar: (ids) async {
        llamadas.add(ids);
        final error = fallo;
        if (error != null) throw error;
        return [for (final id in ids) if (id != 'nota') url(id)];
      },
    );
  });

  test('junta en una llamada los ids pedidos en el mismo ciclo', () async {
    final resultados = await Future.wait([
      repositorio.obtener('a'),
      repositorio.obtener('b'),
      repositorio.obtener('a'),
      repositorio.obtener('nota'),
    ]);

    expect(llamadas, [
      ['a', 'b', 'nota'],
    ]);
    expect(resultados.map((u) => u?.idRecuerdo), ['a', 'b', 'a', null]);
  });

  test('usa la caché mientras la URL siga vigente', () async {
    await repositorio.obtener('a');
    await repositorio.obtener('a');
    expect(llamadas, hasLength(1));

    // A menos de 5 minutos de caducar se vuelve a pedir.
    ahora = ahora.add(const Duration(minutes: 56));
    await repositorio.obtener('a');
    expect(llamadas, hasLength(2));
  });

  test('parte los lotes grandes en grupos de 60', () async {
    await Future.wait([
      for (var i = 0; i < 61; i++) repositorio.obtener('id-$i'),
    ]);
    expect(llamadas.map((l) => l.length), [60, 1]);
  });

  test('si la función falla devuelve null (la UI usa el respaldo)', () async {
    fallo = Exception('sin red');
    expect(await repositorio.obtener('a'), isNull);
  });

  test('UrlMedio.desdeJson falla cerrado', () {
    expect(
      UrlMedio.desdeJson({
        'id': 'a',
        'url': 'https://x',
        'url_miniatura': null,
        'expira_en': '2026-10-03T19:00:00.000Z',
      })?.expiraEn,
      DateTime.utc(2026, 10, 3, 19),
    );
    expect(
      UrlMedio.desdeJson({
        'id': 'a',
        'url': 'http://inseguro',
        'expira_en': '2026-10-03T19:00:00.000Z',
      }),
      isNull,
    );
    expect(UrlMedio.desdeJson({'id': 'a'}), isNull);
  });
}
