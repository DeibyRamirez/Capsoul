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
      expect(RutasApp.revisaTuCorreo, '/revisa-tu-correo');
      expect(RutasApp.nuevaContrasena, '/nueva-contrasena');
    });

    test('revisaTuCorreoPara codifica el correo y el reenvío', () {
      expect(
        RutasApp.revisaTuCorreoPara('ana+1@capsoul.app'),
        '/revisa-tu-correo?correo=ana%2B1%40capsoul.app',
      );
      expect(
        Uri.parse(RutasApp.revisaTuCorreoPara('a@b.co', reenviar: true))
            .queryParameters,
        {'correo': 'a@b.co', 'reenviar': '1'},
      );
    });

    test('en modo recuperación con sesión todo va a /nueva-contrasena', () {
      for (final ubicacion in ['/inicio', '/yo', '/iniciar-sesion']) {
        expect(
          resolverRedireccionAutenticacion(
            sesionIniciada: true,
            ubicacion: ubicacion,
            modoRecuperacion: true,
          ),
          RutasApp.nuevaContrasena,
        );
      }
      expect(
        resolverRedireccionAutenticacion(
          sesionIniciada: true,
          ubicacion: RutasApp.nuevaContrasena,
          modoRecuperacion: true,
        ),
        isNull,
      );
    });

    test('/nueva-contrasena fuera del modo recuperación no se abre', () {
      expect(
        resolverRedireccionAutenticacion(
          sesionIniciada: true,
          ubicacion: RutasApp.nuevaContrasena,
        ),
        RutasApp.inicio,
      );
      expect(
        resolverRedireccionAutenticacion(
          sesionIniciada: false,
          ubicacion: RutasApp.nuevaContrasena,
        ),
        RutasApp.iniciarSesion,
      );
    });
  });
}
