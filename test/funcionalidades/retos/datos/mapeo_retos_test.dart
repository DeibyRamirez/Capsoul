import 'package:capsoul/funcionalidades/retos/datos/mapeo_retos.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('retoDesdeFila mapea pasos y completado', () {
    final reto = retoDesdeFila({
      'id': 'r1',
      'slug': 'foto_con_musica',
      'titulo': 'Música y foto',
      'descripcion': 'Desc',
      'pasos': ['Paso 1', 'Paso 2'],
      'orden': 3,
      'criterio_clave': 'recuerdo_foto_con_musica',
      'completado': true,
      'completado_en': '2026-10-16T12:00:00Z',
    });
    expect(reto.slug, 'foto_con_musica');
    expect(reto.pasos, ['Paso 1', 'Paso 2']);
    expect(reto.completado, isTrue);
    expect(reto.completadoEn, isNotNull);
  });
}
