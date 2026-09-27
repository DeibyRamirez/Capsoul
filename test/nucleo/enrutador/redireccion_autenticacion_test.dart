import 'package:capsoul/nucleo/enrutador/rutas_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolverRedireccionAutenticacion', () {
    test('sin sesión, las rutas protegidas van a /iniciar-sesion', () {
      for (final ubicacion in ['/inicio', '/yo', '/crear', '/']) {
        expect(
          resolverRedireccionAutenticacion(
            sesionIniciada: false,
            ubicacion: ubicacion,
          ),
          RutasApp.iniciarSesion,
        );
      }
    });

    test('sin sesión, las rutas de autenticación se permiten', () {
      for (final ubicacion in RutasApp.rutasAutenticacion) {
        expect(
          resolverRedireccionAutenticacion(
            sesionIniciada: false,
            ubicacion: ubicacion,
          ),
          isNull,
        );
      }
    });

    test('con sesión, las rutas de autenticación y / van a /inicio', () {
      for (final ubicacion in [...RutasApp.rutasAutenticacion, '/']) {
        expect(
          resolverRedireccionAutenticacion(
            sesionIniciada: true,
            ubicacion: ubicacion,
          ),
          RutasApp.inicio,
        );
      }
    });

    test('con sesión, las rutas protegidas se permiten', () {
      expect(
        resolverRedireccionAutenticacion(
          sesionIniciada: true,
          ubicacion: '/momentos',
        ),
        isNull,
      );
      expect(
        resolverRedireccionAutenticacion(
          sesionIniciada: true,
          ubicacion: '/crear/video',
        ),
        isNull,
      );
    });

    test('las rutas de autenticación están en español', () {
      expect(RutasApp.iniciarSesion, '/iniciar-sesion');
      expect(RutasApp.registro, '/registro');
      expect(RutasApp.recuperar, '/recuperar');
    });
  });
}
