import 'package:capsoul/nucleo/formato/valor_monetario.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatea miles con punto cada tres dígitos', () {
    expect(formatearMiles('1250000'), '1.250.000');
    expect(formatearMiles('1.250.000'), '1.250.000');
    expect(formatearMiles('abc'), '');
    expect(formatearMiles('12a3'), '123');
  });

  test('parsea el entero ignorando puntos', () {
    expect(parsearEnteroMiles('1.250.000'), 1250000);
    expect(parsearEnteroMiles(''), isNull);
    expect(parsearEnteroMiles('12'), 12);
  });
}
