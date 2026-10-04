import 'dart:convert';
import 'dart:io';

import 'package:capsoul/funcionalidades/elementos/datos/cliente_firma_subida.dart';
import 'package:capsoul/funcionalidades/elementos/datos/repositorio_medios_cloudinary.dart';
import 'package:capsoul/funcionalidades/elementos/dominio/elemento_borrador.dart';
import 'package:capsoul/funcionalidades/elementos/dominio/fallo_medios.dart';
import 'package:capsoul/funcionalidades/elementos/dominio/tipo_elemento.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _FirmasFalsas implements ClienteFirmaSubida {
  FalloMedios? fallo;
  final List<TipoElemento> pedidas = [];

  @override
  Future<FirmaSubida> solicitarFirma({
    required TipoElemento tipo,
    required int bytes,
    Duration? duracion,
    String? formato,
  }) async {
    final error = fallo;
    if (error != null) throw error;
    pedidas.add(tipo);
    return const FirmaSubida(
      urlSubida: 'https://api.cloudinary.com/v1_1/nube/image/upload',
      parametros: {
        'api_key': '123',
        'timestamp': '1759500000',
        'signature': 'firma',
        'public_id': 'capsoul/aleatorio',
        'type': 'authenticated',
      },
    );
  }
}

void main() {
  late Directory carpeta;
  late ElementoBorrador foto;

  setUp(() async {
    carpeta = await Directory.systemTemp.createTemp('capsoul_prueba');
    final archivo = File('${carpeta.path}/foto.jpg');
    await archivo.writeAsBytes(List.filled(10, 1));
    foto = ElementoBorrador(
      idLocal: 'l1',
      tipo: TipoElemento.foto,
      rutaArchivo: archivo.path,
      bytes: 10,
      formato: 'jpg',
    );
  });

  tearDown(() => carpeta.delete(recursive: true));

  test('sube con los parámetros firmados y mapea la respuesta', () async {
    late http.BaseRequest enviada;
    final cliente = MockClient.streaming((solicitud, cuerpo) async {
      enviada = solicitud;
      await cuerpo.drain<void>();
      return http.StreamedResponse(
        Stream.value(utf8.encode(jsonEncode({
          'public_id': 'capsoul/aleatorio',
          'resource_type': 'image',
          'type': 'authenticated',
          'bytes': 10,
          'version': 7,
          'format': 'jpg',
          'width': 1600,
          'height': 1200,
        }))),
        200,
      );
    });
    final repositorio =
        RepositorioMediosCloudinary(_FirmasFalsas(), clienteHttp: cliente);

    final medio = await repositorio.subir(foto);

    expect(enviada.url.path, '/v1_1/nube/image/upload');
    final multipart = enviada as http.MultipartRequest;
    expect(multipart.fields['type'], 'authenticated');
    expect(multipart.fields['signature'], 'firma');
    expect(multipart.files.single.field, 'file');
    expect(medio.publicId, 'capsoul/aleatorio');
    expect(medio.ancho, 1600);
    expect(medio.version, 7);
  });

  test('si la función no está desplegada, avisa sin subir nada', () async {
    var llamadas = 0;
    final cliente = MockClient((_) async {
      llamadas++;
      return http.Response('', 200);
    });
    final firmas = _FirmasFalsas()..fallo = const FalloMedios.subidaNoDisponible();
    final repositorio =
        RepositorioMediosCloudinary(firmas, clienteHttp: cliente);

    await expectLater(
      repositorio.subir(foto),
      throwsA(isA<FalloMedios>().having(
        (f) => f.codigo,
        'codigo',
        FalloMedios.codigoSubidaNoDisponible,
      )),
    );
    expect(llamadas, 0);
  });

  test('un error de Cloudinary se traduce a subida fallida', () async {
    final cliente = MockClient((_) async => http.Response('{}', 401));
    final repositorio =
        RepositorioMediosCloudinary(_FirmasFalsas(), clienteHttp: cliente);

    await expectLater(
      repositorio.subir(foto),
      throwsA(isA<FalloMedios>().having(
        (f) => f.codigo,
        'codigo',
        FalloMedios.codigoSubidaFallida,
      )),
    );
  });

  test('rechaza una respuesta que no sea de entrega authenticated', () {
    expect(
      RepositorioMediosCloudinary.medioDesdeRespuesta({
        'public_id': 'p',
        'resource_type': 'image',
        'type': 'upload',
        'bytes': 1,
      }),
      isNull,
    );
  });
}
