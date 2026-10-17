import 'package:capsoul/funcionalidades/retos/dominio/reto.dart';
import 'package:capsoul/funcionalidades/retos/presentacion/clasificacion_retos_ui.dart';
import 'package:flutter_test/flutter_test.dart';

Reto _reto(int orden, {bool completado = false}) => Reto(
      id: 'r$orden',
      slug: 'slug_$orden',
      titulo: 'Reto $orden',
      descripcion: 'Desc $orden',
      pasos: const ['Paso'],
      orden: orden,
      criterioClave: 'test',
      completado: completado,
    );

void main() {
  test('cuatro activos asignan diario, dos semanales y especial', () {
    final lista = [_reto(1), _reto(2), _reto(3), _reto(4)];
    final c = clasificarRetosParaUi(lista);

    expect(c.diario?.orden, 1);
    expect(c.semanales.map((r) => r.orden), [2, 3]);
    expect(c.especial?.orden, 4);
    expect(c.restoActivos, isEmpty);
  });

  test('tres activos no muestran especial', () {
    final lista = [_reto(1), _reto(2), _reto(3)];
    final c = clasificarRetosParaUi(lista);

    expect(c.especial, isNull);
    expect(c.restoActivos, isEmpty);
    expect(c.semanales.length, 2);
  });

  test('completados ordenados y contados', () {
    final lista = [
      _reto(1, completado: true),
      _reto(2),
      _reto(3, completado: true),
    ];
    final c = clasificarRetosParaUi(lista);

    expect(c.totalCompletados, 2);
    expect(c.completados.length, 2);
    expect(c.diario?.orden, 2);
  });
}
