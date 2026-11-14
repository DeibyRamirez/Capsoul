import 'dart:async';

import 'package:capsoul/funcionalidades/musica/aplicacion/intentar_cargar_preview_con_refresco.dart';
import 'package:capsoul/funcionalidades/musica/datos/repositorio_musica_con_cache.dart';
import 'package:capsoul/funcionalidades/musica/dominio/cache_busquedas_musica.dart';
import 'package:capsoul/funcionalidades/musica/dominio/fallo_musica.dart';
import 'package:capsoul/funcionalidades/musica/dominio/referencia_musica.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../ayudantes/falsos_musica.dart';

void main() {
  final inicio = DateTime.utc(2026, 11, 3, 12);
  var ahora = inicio;
  late CatalogoMusicaFalso interno;
  late RepositorioMusicaConCache repo;

  setUp(() {
    ahora = inicio;
    interno = CatalogoMusicaFalso(
      respuestas: {
        'HOLA': [pistaDeezerPrueba()],
        'hola': [pistaDeezerPrueba()],
      },
      porId: {'3135556': pistaDeezerPrueba()},
    );
    repo = RepositorioMusicaConCache(
      interno,
      cache: CacheBusquedasMusica(reloj: () => ahora),
    );
  });

  test('dos búsquedas iguales en curso comparten el mismo Future', () async {
    final pendiente = Completer<List<ReferenciaMusica>>();
    interno.pendientes['HOLA'] = pendiente;

    final primera = repo.buscar('HOLA');
    final segunda = repo.buscar('  hola  ');

    expect(identical(primera, segunda), isTrue);
    expect(interno.consultas, ['HOLA']);

    pendiente.complete([pistaDeezerPrueba()]);
    final resultados = await Future.wait([primera, segunda]);
    expect(resultados.first.single.previewUrl, isNotNull);
    expect(identical(resultados[0], resultados[1]), isTrue);

    final desdeCache = await repo.buscar('Hola');
    expect(interno.consultas, ['HOLA']);
    expect(desdeCache.single.previewUrl, isNull);
    expect(desdeCache.single.hayClipConocido, isTrue);
    expect(debePedirPreviewFresco(desdeCache.single), isTrue);
    expect(desdeCache.single.aFilaBd()['musica_preview_url'], isNull);
  });

  test('un fallo no se guarda y el reintento sí llama al catálogo', () async {
    interno.fallo = const FalloMusica(TipoFalloMusica.tiempoAgotado);
    await expectLater(
      repo.buscar('hola'),
      throwsA(
        isA<FalloMusica>().having(
          (fallo) => fallo.tipo,
          'tipo',
          TipoFalloMusica.tiempoAgotado,
        ),
      ),
    );

    interno.fallo = null;
    final resultados = await repo.buscar('hola');
    expect(interno.consultas, ['hola', 'hola']);
    expect(resultados, hasLength(1));
  });

  test('pasada la vigencia vuelve a consultar', () async {
    await repo.buscar('hola');
    ahora = inicio.add(const Duration(minutes: 15));
    await repo.buscar('hola');
    expect(interno.consultas, ['hola', 'hola']);
  });

  test(
    'obtenerPorId no usa la caché: cada reproducción pide /track/<id>',
    () async {
      final primera = await repo.obtenerPorId('3135556');
      final segunda = await repo.obtenerPorId('3135556');
      expect(interno.idsPedidos, ['3135556', '3135556']);
      expect(primera?.previewUrl, isNotNull);
      expect(segunda?.previewUrl, isNotNull);
    },
  );

  test('una consulta vacía no llama al catálogo', () async {
    expect(await repo.buscar('   '), isEmpty);
    expect(interno.consultas, isEmpty);
  });
}
