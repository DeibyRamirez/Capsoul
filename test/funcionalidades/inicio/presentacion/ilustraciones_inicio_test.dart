import 'dart:io';

import 'package:capsoul/funcionalidades/inicio/presentacion/recursos_ilustraciones_inicio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const rutas = [
    IlustracionesInicio.recuerdos,
    IlustracionesInicio.retos,
    IlustracionesInicio.capsulas,
    IlustracionesInicio.herencias,
  ];

  test('las ilustraciones de inicio existen y no son stubs vacíos', () {
    for (final ruta in rutas) {
      final archivo = File(ruta);
      expect(archivo.existsSync(), isTrue, reason: ruta);
      expect(
        archivo.lengthSync(),
        greaterThan(1024),
        reason: '$ruta es un stub (<1 KB)',
      );
    }
  });
}
