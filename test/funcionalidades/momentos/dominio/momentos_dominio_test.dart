import 'package:capsoul/funcionalidades/elementos/dominio/tipo_elemento.dart';
import 'package:capsoul/funcionalidades/momentos/dominio/distribucion_bento.dart';
import 'package:capsoul/funcionalidades/momentos/dominio/fallo_momento.dart';
import 'package:capsoul/funcionalidades/momentos/dominio/nuevo_momento.dart';
import 'package:capsoul/funcionalidades/momentos/dominio/validador_momento.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../ayudantes/falsos_recuerdos.dart';

void main() {
  group('distribuirBento', () {
    test('vacío no ocupa filas', () {
      final d = distribuirBento(const []);
      expect(d.celdas, isEmpty);
      expect(d.filas, 0);
    });

    test('alterna fotos grandes y anchas y llena la mitad más baja', () {
      final d = distribuirBento([
        recuerdoPrueba('f1'), // grande 2×2 izquierda
        recuerdoPrueba('f2'), // ancha 2×1 derecha
        recuerdoPrueba('a1', tipo: TipoElemento.audio), // 2×1 derecha
        recuerdoPrueba('n1', tipo: TipoElemento.texto), // 2×2 izquierda
        recuerdoPrueba('v1', tipo: TipoElemento.video), // grande, derecha
      ]);
      String r(CeldaBento c) => '${c.recuerdo.id}:${c.columna},${c.fila},'
          '${c.ancho}x${c.alto}';
      expect(d.celdas.map(r), [
        'f1:0,0,2x2',
        'f2:2,0,2x1',
        'a1:2,1,2x1',
        'n1:0,2,2x2',
        'v1:2,2,2x2',
      ]);
      expect(d.filas, 4);
    });

    test('ninguna celda se sale de las 4 columnas ni se solapa', () {
      final recuerdos = [
        for (var i = 0; i < 20; i++)
          recuerdoPrueba('r$i', tipo: TipoElemento.values[i % 4]),
      ];
      final d = distribuirBento(recuerdos);
      final ocupadas = <String>{};
      for (final c in d.celdas) {
        expect(c.columna + c.ancho, lessThanOrEqualTo(columnasBento));
        for (var x = c.columna; x < c.columna + c.ancho; x++) {
          for (var y = c.fila; y < c.fila + c.alto; y++) {
            expect(ocupadas.add('$x,$y'), isTrue, reason: '$c solapa');
          }
        }
      }
    });
  });

  group('ValidadorMomento', () {
    NuevoMomento nuevo({
      String titulo = 'Viaje',
      int cantidad = 1,
      String? portada,
      String? descripcion,
    }) =>
        NuevoMomento(
          titulo: titulo,
          descripcion: descripcion,
          portadaId: portada,
          recuerdos: [
            for (var i = 0; i < cantidad; i++)
              recuerdoPrueba('r$i', tipo: i == 1 ? TipoElemento.texto : TipoElemento.foto),
          ],
        );

    test('acepta un momento completo', () {
      expect(ValidadorMomento.validar(nuevo(portada: 'r0')), isNull);
    });

    test('rechaza nombre vacío o largo, sin recuerdos o más de 60', () {
      expect(ValidadorMomento.validar(nuevo(titulo: '  '))?.codigo,
          FalloMomento.codigoTituloInvalido);
      expect(ValidadorMomento.validar(nuevo(titulo: 'a' * 81))?.codigo,
          FalloMomento.codigoTituloInvalido);
      expect(ValidadorMomento.validar(nuevo(cantidad: 0))?.codigo,
          FalloMomento.codigoSinRecuerdos);
      expect(ValidadorMomento.validar(nuevo(cantidad: 61))?.codigo,
          FalloMomento.codigoDemasiadosRecuerdos);
      expect(ValidadorMomento.validar(nuevo(descripcion: 'a' * 501))?.codigo,
          FalloMomento.codigoDescripcionLarga);
    });

    test('la portada debe ser una foto o video del momento', () {
      expect(ValidadorMomento.validar(nuevo(cantidad: 2, portada: 'r1'))?.codigo,
          FalloMomento.codigoPortadaInvalida);
      expect(ValidadorMomento.validar(nuevo(portada: 'otro'))?.codigo,
          FalloMomento.codigoPortadaInvalida);
    });
  });
}
