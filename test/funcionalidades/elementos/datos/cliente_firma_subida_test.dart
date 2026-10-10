import 'package:capsoul/funcionalidades/elementos/datos/repositorio_medios_cloudinary.dart';
import 'package:capsoul/funcionalidades/elementos/dominio/fallo_medios.dart';
import 'package:capsoul/nucleo/infraestructura/cliente_funciones_api.dart';
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

  group('RepositorioMediosCloudinary.traducirErrorFuncion', () {
    test('404 (función sin desplegar) da un mensaje claro', () {
      final fallo = RepositorioMediosCloudinary.traducirErrorFuncion(
        const ErrorFuncionesApi(estado: 404),
      );
      expect(fallo.codigo, FalloMedios.codigoSubidaNoDisponible);
      expect(fallo.mensaje, contains('aún no está disponible'));
    });

    test('cuota excedida', () {
      final fallo = RepositorioMediosCloudinary.traducirErrorFuncion(
        const ErrorFuncionesApi(
          estado: 422,
          detalles: {'codigo': 'cuota_excedida', 'mensaje': 'x'},
        ),
      );
      expect(fallo.codigo, FalloMedios.codigoCuotaExcedida);
    });

    test('422 con mensaje del servidor lo conserva', () {
      final fallo = RepositorioMediosCloudinary.traducirErrorFuncion(
        const ErrorFuncionesApi(
          estado: 422,
          detalles: {'codigo': 'excede_tamano', 'mensaje': 'La foto supera 2 MB.'},
        ),
      );
      expect(fallo.codigo, 'excede_tamano');
      expect(fallo.mensaje, 'La foto supera 2 MB.');
    });

    test('otros errores son genéricos', () {
      expect(
        RepositorioMediosCloudinary.traducirErrorFuncion(
          const ErrorFuncionesApi(estado: 500),
        ).codigo,
        FalloMedios.codigoSubidaFallida,
      );
    });
  });
}
