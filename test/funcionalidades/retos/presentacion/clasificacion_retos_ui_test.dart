import 'package:capsoul/funcionalidades/retos/dominio/reto.dart';
import 'package:capsoul/funcionalidades/retos/presentacion/clasificacion_retos_ui.dart';
import 'package:flutter_test/flutter_test.dart';

Reto _reto(
  int orden, {
  bool completado = false,
  String? slug,
  String criterio = 'test',
}) => Reto(
  id: 'r$orden',
  slug: slug ?? 'slug_$orden',
  titulo: 'Reto $orden',
  descripcion: 'Desc $orden',
  pasos: const ['Paso'],
  orden: orden,
  criterioClave: criterio,
  completado: completado,
);

void main() {
  test('cuatro activos asignan diario, dos semanales y especial', () {
    final lista = [
      _reto(1),
      _reto(2),
      _reto(3),
      _reto(4, slug: ClasificacionRetosUi.slugEspecial),
    ];
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

  test('las entradas restantes se agrupan por tipo de acción', () {
    final grupos = agruparRestoActivos([
      _reto(1, criterio: 'nombre_usuario'),
      _reto(2, criterio: 'recuerdo_foto'),
      _reto(3, criterio: 'capsula_programada'),
      _reto(4, criterio: 'momento_tres_recuerdos'),
      _reto(5, criterio: 'herencia_con_capsula'),
      _reto(6, criterio: 'recuerdo_nota'),
    ]);

    expect(grupos.map((grupo) => grupo.titulo), [
      'Primeros pasos',
      'Recuerdos',
      'Cápsulas',
      'Momentos',
      'Legado',
    ]);
    expect(grupos[1].retos.map((reto) => reto.orden), [2, 6]);
    expect(grupos[4].retos.single.orden, 5);
  });

  test('si solo queda la especial, no se muestra como diaria', () {
    final c = clasificarRetosParaUi([
      _reto(25, slug: ClasificacionRetosUi.slugEspecial),
    ]);

    expect(c.diario, isNull);
    expect(c.especial?.orden, 25);
  });

  test('la entrada especial no se repite en el resto', () {
    final lista = [
      _reto(1),
      _reto(2),
      _reto(3),
      _reto(25, slug: ClasificacionRetosUi.slugEspecial),
    ];
    final c = clasificarRetosParaUi(lista);

    expect(c.especial?.orden, 25);
    expect(c.restoActivos, isEmpty);
  });
}
