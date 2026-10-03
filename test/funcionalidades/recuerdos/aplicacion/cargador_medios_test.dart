import 'dart:io';

import 'package:capsoul/funcionalidades/recuerdos/aplicacion/cargador_medios.dart';
import 'package:capsoul/funcionalidades/recuerdos/dominio/enlace_medio.dart';
import 'package:capsoul/funcionalidades/recuerdos/dominio/url_medio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../ayudantes/falsos_recuerdos.dart';

void main() {
  late RepositorioUrlsMedioFalso urls;
  late ArchivosMedioFalso archivos;
  late CargadorMedios cargador;

  final expira = DateTime.utc(2026, 10, 10);
  const miniatura = (
    idRecuerdo: 'r1',
    publicId: 'capsoul/a',
    variante: VarianteMedio.miniatura,
  );
  const original = (
    idRecuerdo: 'r1',
    publicId: 'capsoul/a',
    variante: VarianteMedio.original,
  );

  setUp(() {
    urls = RepositorioUrlsMedioFalso({
      'r1': UrlMedio(
        idRecuerdo: 'r1',
        publicId: 'capsoul/a',
        original: EnlaceFirmado(url: 'https://o', expiraEn: expira),
        miniatura: EnlaceFirmado(url: 'https://m', expiraEn: expira),
      ),
    });
    archivos = ArchivosMedioFalso();
    cargador = CargadorMedios(urls: urls, archivos: archivos);
  });

  test('si el archivo está en el dispositivo no pide enlace ni descarga', () async {
    archivos.archivos['capsoul/a|miniatura'] = File('/cache/a');
    expect((await cargador.archivo(miniatura))?.path, '/cache/a');
    expect(urls.pedidos, isEmpty);
    expect(archivos.descargas, isEmpty);
  });

  test('si falta, pide el enlace de esa variante y lo guarda por public_id', () async {
    await cargador.archivo(miniatura);
    expect(urls.pedidos, ['capsoul/a|miniatura']);
    expect(archivos.descargas, ['https://m']);
    expect(archivos.archivos.keys, ['capsoul/a|miniatura']);

    // La segunda vez sale del dispositivo.
    await cargador.archivo(miniatura);
    expect(archivos.descargas, hasLength(1));

    // El original es otra entrada (solo se pide en el detalle).
    await cargador.archivo(original);
    expect(archivos.descargas, ['https://m', 'https://o']);
  });

  test('varios widgets a la vez descargan una sola vez', () async {
    await Future.wait([for (var i = 0; i < 5; i++) cargador.archivo(miniatura)]);
    expect(archivos.descargas, hasLength(1));
  });

  test('sin enlace (no visible o sin red) devuelve null', () async {
    const ajeno = (
      idRecuerdo: 'otro',
      publicId: 'capsoul/x',
      variante: VarianteMedio.miniatura,
    );
    expect(await cargador.archivo(ajeno), isNull);
    expect(archivos.descargas, isEmpty);
  });
}
