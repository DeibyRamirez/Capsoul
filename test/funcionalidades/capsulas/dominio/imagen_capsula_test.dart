import 'dart:io';

import 'package:capsoul/funcionalidades/capsulas/dominio/imagen_capsula.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('claves estables, unicas y con formato capsula_NN', () {
    final claves = ImagenCapsula.values.map((i) => i.clave).toList();
    expect(claves.toSet().length, claves.length);
    for (final clave in claves) {
      expect(RegExp(r'^capsula_[0-9]{2}$').hasMatch(clave), isTrue);
    }
    expect(ImagenCapsula.corazon.clave, 'capsula_01');
    expect(ImagenCapsula.arcoiris.clave, 'capsula_16');
  });

  test('clave nula o desconocida usa la imagen por defecto', () {
    expect(ImagenCapsula.desdeClave(null), ImagenCapsula.porDefecto);
    expect(ImagenCapsula.desdeClave('capsula_99'), ImagenCapsula.porDefecto);
    expect(ImagenCapsula.buscar('otra'), isNull);
    expect(ImagenCapsula.desdeClave('capsula_05'), ImagenCapsula.barcoOceano);
  });

  test('cada imagen del catalogo existe como asset', () {
    for (final imagen in ImagenCapsula.values) {
      expect(File(imagen.ruta).existsSync(), isTrue, reason: imagen.ruta);
    }
  });
}