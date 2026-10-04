import 'package:capsoul/funcionalidades/autenticacion/presentacion/validadores_autenticacion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('correo', () {
    expect(
      ValidadoresAutenticacion.correo(''),
      'Ingresa tu correo electrónico',
    );
    expect(
      ValidadoresAutenticacion.correo('ana'),
      'Ingresa un correo electrónico válido',
    );
    expect(ValidadoresAutenticacion.correo(' ana@capsoul.app '), isNull);
  });

  test('la contraseña nueva exige mínimo 8 caracteres', () {
    expect(
      ValidadoresAutenticacion.contrasenaNueva(''),
      'Ingresa una contraseña',
    );
    expect(
      ValidadoresAutenticacion.contrasenaNueva('1234567'),
      'La contraseña debe tener al menos 8 caracteres',
    );
    expect(ValidadoresAutenticacion.contrasenaNueva('12345678'), isNull);
  });

  test('confirmar contraseña', () {
    expect(
      ValidadoresAutenticacion.confirmarContrasena('', 'x'),
      'Confirma tu contraseña',
    );
    expect(
      ValidadoresAutenticacion.confirmarContrasena('abc', 'abd'),
      'Las contraseñas no coinciden',
    );
    expect(ValidadoresAutenticacion.confirmarContrasena('abc', 'abc'), isNull);
  });

  test('nombre visible', () {
    expect(ValidadoresAutenticacion.nombreVisible('  '), 'Ingresa tu nombre');
    expect(
      ValidadoresAutenticacion.nombreVisible('a' * 61),
      'El nombre no puede superar 60 caracteres',
    );
    expect(ValidadoresAutenticacion.nombreVisible('Ana'), isNull);
  });
}
