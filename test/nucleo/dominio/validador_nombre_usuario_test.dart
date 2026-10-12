import 'package:capsoul/nucleo/dominio/validador_nombre_usuario.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normaliza arroba y mayúsculas', () {
    expect(ValidadorNombreUsuario.normalizar('@CheiViz'), 'cheiviz');
  });

  test('valida longitud mínima', () {
    expect(ValidadorNombreUsuario.validar('ab'), isNotNull);
    expect(ValidadorNombreUsuario.validar('abc'), isNull);
  });
}
