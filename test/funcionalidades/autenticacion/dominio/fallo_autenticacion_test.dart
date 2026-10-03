import 'package:capsoul/funcionalidades/autenticacion/dominio/fallo_autenticacion.dart';
import 'package:capsoul/nucleo/errores/fallo_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FalloAutenticacion.desdeCodigo', () {
    const esperados = {
      'email_address_invalid': 'El correo electrónico no es válido.',
      'user_banned':
          'Esta cuenta está deshabilitada. Escríbenos si crees que es un error.',
      'invalid_credentials': 'Correo o contraseña incorrectos.',
      'user_not_found': 'Correo o contraseña incorrectos.',
      'email_not_confirmed':
          'Confirma tu correo antes de iniciar sesión. Revisa tu bandeja de '
              'entrada.',
      'user_already_exists': 'Ya existe una cuenta con este correo.',
      'email_exists': 'Ya existe una cuenta con este correo.',
      'weak_password': 'La contraseña es muy débil. Usa al menos 8 caracteres.',
      'over_request_rate_limit':
          'Demasiados intentos. Espera unos minutos e inténtalo de nuevo.',
      'over_email_send_rate_limit':
          'Demasiados intentos. Espera unos minutos e inténtalo de nuevo.',
      'sin_red': 'Sin conexión. Revisa tu internet e inténtalo de nuevo.',
      'signup_disabled':
          'El acceso con correo y contraseña no está habilitado.',
      'session_not_found': 'Tu sesión expiró. Vuelve a iniciar sesión.',
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
        FalloAutenticacion.desdeCodigo('algo_raro').mensaje,
        kMensajeErrorInesperado,
      );
      expect(
        const FalloAutenticacion.desconocido().mensaje,
        kMensajeErrorInesperado,
      );
    });

    test('esUsuarioNoEncontrado solo para user_not_found', () {
      expect(
        FalloAutenticacion.desdeCodigo('user_not_found').esUsuarioNoEncontrado,
        isTrue,
      );
      expect(
        FalloAutenticacion.desdeCodigo('invalid_credentials')
            .esUsuarioNoEncontrado,
        isFalse,
      );
    });

    test('mensajeParaUsuario usa el mensaje de FalloApp', () {
      expect(
        mensajeParaUsuario(FalloAutenticacion.desdeCodigo('user_banned')),
        startsWith('Esta cuenta está deshabilitada'),
      );
      expect(mensajeParaUsuario(Exception('x')), kMensajeErrorInesperado);
    });
  });
}
