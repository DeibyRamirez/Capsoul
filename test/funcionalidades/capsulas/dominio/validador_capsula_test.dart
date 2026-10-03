import 'package:capsoul/funcionalidades/capsulas/dominio/fallo_capsula.dart';
import 'package:capsoul/funcionalidades/capsulas/dominio/nueva_capsula.dart';
import 'package:capsoul/funcionalidades/capsulas/dominio/validador_capsula.dart';
import 'package:capsoul/funcionalidades/elementos/dominio/elemento_borrador.dart';
import 'package:capsoul/funcionalidades/elementos/dominio/tipo_elemento.dart';
import 'package:flutter_test/flutter_test.dart';

ElementoBorrador _nota(int i) => ElementoBorrador(
      idLocal: 'n$i',
      tipo: TipoElemento.texto,
      texto: 'nota $i',
    );

void main() {
  final ahora = DateTime(2026, 10, 3, 10);

  NuevaCapsula capsula({
    String titulo = 'Para Jacobo',
    DateTime? fecha,
    int elementos = 1,
  }) =>
      NuevaCapsula(
        titulo: titulo,
        fechaApertura: fecha ?? DateTime(2046, 8, 13, 8),
        elementos: [for (var i = 0; i < elementos; i++) _nota(i)],
      );

  test('una cápsula completa es válida', () {
    expect(ValidadorCapsula.validar(capsula(), ahora: ahora), isNull);
  });

  test('el título debe tener de 1 a 120 caracteres', () {
    expect(
      ValidadorCapsula.validar(capsula(titulo: '  '), ahora: ahora)?.codigo,
      FalloCapsula.codigoTituloInvalido,
    );
    expect(
      ValidadorCapsula.validar(capsula(titulo: 'a' * 121), ahora: ahora)
          ?.codigo,
      FalloCapsula.codigoTituloInvalido,
    );
    expect(
      ValidadorCapsula.validar(capsula(titulo: 'a' * 120), ahora: ahora),
      isNull,
    );
  });

  test('la fecha debe estar al menos 1 minuto en el futuro', () {
    expect(
      ValidadorCapsula.validar(
        capsula(fecha: ahora.add(const Duration(seconds: 30))),
        ahora: ahora,
      )?.codigo,
      FalloCapsula.codigoFechaInvalida,
    );
    expect(
      ValidadorCapsula.validar(
        capsula(fecha: ahora.subtract(const Duration(days: 1))),
        ahora: ahora,
      )?.codigo,
      FalloCapsula.codigoFechaInvalida,
    );
  });

  test('exige entre 1 y 10 elementos', () {
    expect(
      ValidadorCapsula.validar(capsula(elementos: 0), ahora: ahora)?.codigo,
      FalloCapsula.codigoSinElementos,
    );
    expect(
      ValidadorCapsula.validar(capsula(elementos: 10), ahora: ahora),
      isNull,
    );
    expect(
      ValidadorCapsula.validar(capsula(elementos: 11), ahora: ahora)?.codigo,
      FalloCapsula.codigoDemasiadosElementos,
    );
  });

  test('el primer día seleccionable es mañana', () {
    expect(
      ValidadorCapsula.primerDiaSeleccionable(DateTime(2026, 12, 31, 23)),
      DateTime(2027, 1, 1),
    );
  });
}
