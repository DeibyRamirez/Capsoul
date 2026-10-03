import 'package:capsoul/funcionalidades/elementos/datos/cliente_firma_subida.dart';
import 'package:capsoul/funcionalidades/elementos/dominio/fallo_medios.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FirmaSubida.desdeJson', () {
    test('lee la URL y convierte los parámetros a texto', () {
      final firma = FirmaSubida.desdeJson({
        'url_subida': 'https://api.cloudinary.com/v1_1/nube/image/upload',
        'parametros': {
          'api_key': '123',
          'timestamp': 1759500000,
          'signature': 'abc',
          'public_id': 'capsoul/x1',
          'type': 'authenticated',
        },
      });
      expect(firma?.urlSubida, endsWith('/image/upload'));
      expect(firma?.parametros['timestamp'], '1759500000');
      expect(firma?.parametros['type'], 'authenticated');
    });

    test('falla cerrado si falta la firma o la URL no es https', () {
      expect(
        FirmaSubida.desdeJson({
          'url_subida': 'https://api.cloudinary.com/v1_1/nube/image/upload',
          'parametros': {'api_key': '1', 'timestamp': 1, 'public_id': 'p'},
        }),
        isNull,
      );
      expect(
        FirmaSubida.desdeJson({
          'url_subida': 'http://inseguro',
          'parametros': {
            'api_key': '1',
            'timestamp': 1,
            'signature': 's',
            'public_id': 'p',
          },
        }),
        isNull,
      );
      expect(FirmaSubida.desdeJson('texto'), isNull);
    });
  });

  group('ClienteFirmaSubidaSupabase.traducirErrorFuncion', () {
    test('404 (función sin desplegar) da un mensaje claro', () {
      final fallo = ClienteFirmaSubidaSupabase.traducirErrorFuncion(404, null);
      expect(fallo.codigo, FalloMedios.codigoSubidaNoDisponible);
      expect(fallo.mensaje, contains('aún no está disponible'));
    });

    test('cuota excedida', () {
      final fallo = ClienteFirmaSubidaSupabase.traducirErrorFuncion(
        422,
        {'codigo': 'cuota_excedida', 'mensaje': 'x'},
      );
      expect(fallo.codigo, FalloMedios.codigoCuotaExcedida);
    });

    test('422 con mensaje del servidor lo conserva', () {
      final fallo = ClienteFirmaSubidaSupabase.traducirErrorFuncion(
        422,
        {'codigo': 'excede_tamano', 'mensaje': 'La foto supera 2 MB.'},
      );
      expect(fallo.codigo, 'excede_tamano');
      expect(fallo.mensaje, 'La foto supera 2 MB.');
    });

    test('otros errores son genéricos', () {
      expect(
        ClienteFirmaSubidaSupabase.traducirErrorFuncion(500, null).codigo,
        FalloMedios.codigoSubidaFallida,
      );
    });
  });
}
