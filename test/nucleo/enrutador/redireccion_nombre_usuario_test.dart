import 'package:capsoul/nucleo/enrutador/rutas_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolverRedireccionNombreUsuario', () {
    test('sin sesión no redirige', () {
      expect(
        resolverRedireccionNombreUsuario(
          sesionIniciada: false,
          ubicacion: RutasApp.inicio,
          necesitaNombreUsuario: true,
        ),
        isNull,
      );
    });

    test('con sesión y falta @, cualquier ruta va a elegir-usuario', () {
      expect(
        resolverRedireccionNombreUsuario(
          sesionIniciada: true,
          ubicacion: RutasApp.inicio,
          necesitaNombreUsuario: true,
        ),
        RutasApp.elegirNombreUsuario,
      );
    });

    test('en elegir-usuario con @ listo, va a inicio', () {
      expect(
        resolverRedireccionNombreUsuario(
          sesionIniciada: true,
          ubicacion: RutasApp.elegirNombreUsuario,
          necesitaNombreUsuario: false,
        ),
        RutasApp.inicio,
      );
    });

    test('con perfil cargando no redirige (evita bucle tras guardar @)', () {
      expect(
        resolverRedireccionNombreUsuario(
          sesionIniciada: true,
          ubicacion: RutasApp.elegirNombreUsuario,
          necesitaNombreUsuario: false,
          perfilCargando: true,
        ),
        isNull,
      );
      expect(
        resolverRedireccionNombreUsuario(
          sesionIniciada: true,
          ubicacion: RutasApp.inicio,
          necesitaNombreUsuario: true,
          perfilCargando: true,
        ),
        isNull,
      );
    });
  });
}
