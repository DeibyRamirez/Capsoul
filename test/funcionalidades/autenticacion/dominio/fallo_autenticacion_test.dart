import 'package:capsoul/funcionalidades/autenticacion/dominio/fallo_autenticacion.dart';
import 'package:capsoul/nucleo/errores/fallo_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FalloAutenticacion.desdeCodigo', () {
    const esperados = {
      'invalid-email': 'El correo electrónico no es válido.',
      'user-disabled':
          'Esta cuenta está deshabilitada. Escríbenos si crees que es un error.',
      'user-not-found': 'Correo o contraseña incorrectos.',
      'wrong-password': 'Correo o contraseña incorrectos.',
      'invalid-credential': 'Correo o contraseña incorrectos.',
      'email-already-in-use': 'Ya existe una cuenta con este correo.',
      'weak-password': 'La contraseña es muy débil. Usa al menos 8 caracteres.',
      'too-many-requests':
          'Demasiados intentos. Espera unos minutos e inténtalo de nuevo.',
      'network-request-failed':
          'Sin conexión. Revisa tu internet e inténtalo de nuevo.',
    };

    esperados.forEach((codigo, mensaje) {
      test('traduce $codigo', () {
        final fallo = FalloAutenticacion.desdeCodigo(codigo);
        expect(fallo.codigo, codigo);
        expect(fallo.mensaje, mensaje);
      });
    });

    test('los códigos desconocidos usan el mensaje genérico', () {
      expect(
        FalloAutenticacion.desdeCodigo('algo-raro').mensaje,
        kMensajeErrorInesperado,
      );
      expect(
        const FalloAutenticacion.desconocido().mensaje,
        kMensajeErrorInesperado,
      );
    });

    test('esUsuarioNoEncontrado solo para user-not-found', () {
      expect(
        FalloAutenticacion.desdeCodigo('user-not-found').esUsuarioNoEncontrado,
        isTrue,
      );
      expect(
        FalloAutenticacion.desdeCodigo('invalid-credential')
            .esUsuarioNoEncontrado,
        isFalse,
      );
    });

    test('mensajeParaUsuario usa el mensaje de FalloApp', () {
      expect(
        mensajeParaUsuario(FalloAutenticacion.desdeCodigo('user-disabled')),
        startsWith('Esta cuenta está deshabilitada'),
      );
      expect(mensajeParaUsuario(Exception('x')), kMensajeErrorInesperado);
    });
  });
}
