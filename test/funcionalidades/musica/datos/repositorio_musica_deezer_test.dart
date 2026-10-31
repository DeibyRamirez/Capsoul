import 'dart:convert';

import 'package:capsoul/funcionalidades/musica/datos/repositorio_musica_deezer.dart';
import 'package:capsoul/funcionalidades/musica/dominio/fallo_musica.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response json(Object cuerpo, [int estado = 200]) => http.Response.bytes(
      utf8.encode(jsonEncode(cuerpo)),
      estado,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

final pistaJson = {
  'id': 1,
  'title': 'Canción',
  'link': 'https://www.deezer.com/track/1',
  'preview': 'https://cdnt-preview.dzcdn.net/1.mp3',
  'artist': {'name': 'Beéle'},
  'album': {'cover_medium': 'https://img/1.jpg'},
};

Matcher falloDe(TipoFalloMusica tipo) =>
    isA<FalloMusica>().having((f) => f.tipo, 'tipo', tipo);

void main() {
  test('buscar llama a /search con q y limit y mapea resultados', () async {
    late Uri pedida;
    final repo = RepositorioMusicaDeezer(MockClient((solicitud) async {
      pedida = solicitud.url;
      return json({
        'data': [pistaJson, {'id': 2}],
        'total': 2,
      });
    }));

    final resultados = await repo.buscar('  beéle  ', limite: 10);

    expect(pedida.host, 'api.deezer.com');
    expect(pedida.path, '/search');
    expect(pedida.queryParameters['q'], 'beéle');
    expect(pedida.queryParameters['limit'], '10');
    expect(resultados, hasLength(1), reason: 'la pista incompleta se ignora');
    expect(resultados.single.titulo, 'Canción');
    expect(resultados.single.artista, 'Beéle');
  });

  test('consulta vacía no hace petición', () async {
    var llamadas = 0;
    final repo = RepositorioMusicaDeezer(MockClient((_) async {
      llamadas++;
      return json({'data': []});
    }));
    expect(await repo.buscar('   '), isEmpty);
    expect(llamadas, 0);
  });

  test('resultado vacío devuelve lista vacía', () async {
    final repo = RepositorioMusicaDeezer(
      MockClient((_) async => json({'data': [], 'total': 0})),
    );
    expect(await repo.buscar('zzzz'), isEmpty);
  });

  test('error de cuota de Deezer (código 4)', () async {
    final repo = RepositorioMusicaDeezer(MockClient((_) async => json({
          'error': {'type': 'Exception', 'message': 'Quota limit exceeded', 'code': 4},
        })));
    expect(repo.buscar('a b'), throwsA(falloDe(TipoFalloMusica.limiteSolicitudes)));
  });

  test('HTTP 500 es fallo de servicio y 429 de cuota', () async {
    final repo500 = RepositorioMusicaDeezer(
      MockClient((_) async => http.Response('x', 500)),
    );
    expect(repo500.buscar('ab'), throwsA(falloDe(TipoFalloMusica.servicio)));
    final repo429 = RepositorioMusicaDeezer(
      MockClient((_) async => http.Response('x', 429)),
    );
    expect(
      repo429.buscar('ab'),
      throwsA(falloDe(TipoFalloMusica.limiteSolicitudes)),
    );
  });

  test('cuerpo que no es JSON es respuesta inválida', () async {
    final repo = RepositorioMusicaDeezer(
      MockClient((_) async => http.Response('<html>', 200)),
    );
    expect(repo.buscar('ab'), throwsA(falloDe(TipoFalloMusica.respuestaInvalida)));
  });

  test('timeout', () async {
    final repo = RepositorioMusicaDeezer(
      MockClient((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return json({'data': []});
      }),
      tiempoMaximo: const Duration(milliseconds: 20),
    );
    expect(repo.buscar('ab'), throwsA(falloDe(TipoFalloMusica.tiempoAgotado)));
  });

  test('sin conexión', () async {
    final repo = RepositorioMusicaDeezer(
      MockClient((_) async => throw http.ClientException('sin red')),
    );
    expect(repo.buscar('ab'), throwsA(falloDe(TipoFalloMusica.sinConexion)));
  });

  test('obtenerPorId pide /track/<id>', () async {
    late Uri pedida;
    final repo = RepositorioMusicaDeezer(MockClient((solicitud) async {
      pedida = solicitud.url;
      return json(pistaJson);
    }));
    final pista = await repo.obtenerPorId('1');
    expect(pedida.path, '/track/1');
    expect(pista?.previewUrl, 'https://cdnt-preview.dzcdn.net/1.mp3');
  });

  test('obtenerPorId devuelve null si Deezer no tiene datos (800)', () async {
    final repo = RepositorioMusicaDeezer(MockClient((_) async => json({
          'error': {'type': 'DataException', 'message': 'no data', 'code': 800},
        })));
    expect(await repo.obtenerPorId('999'), isNull);
  });

  test('obtenerPorId con id no numérico no hace petición', () async {
    var llamadas = 0;
    final repo = RepositorioMusicaDeezer(MockClient((_) async {
      llamadas++;
      return json(pistaJson);
    }));
    expect(await repo.obtenerPorId('spotify:track:1'), isNull);
    expect(llamadas, 0);
  });
}
