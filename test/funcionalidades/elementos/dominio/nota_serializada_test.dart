import 'package:capsoul/funcionalidades/elementos/dominio/nota_serializada.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('texto legacy sin front matter', () {
    final nota = NotaSerializada.parse('Hola **mundo**');
    expect(nota.cuerpo, 'Hola **mundo**');
    expect(nota.estilo.fondo, 'pastelAzul');
  });

  test('markdownAPlano quita negrilla y encabezados', () {
    expect(NotaSerializada.markdownAPlano('**Exotiqueo**'), 'Exotiqueo');
    expect(
      NotaSerializada.markdownAPlano('# Título\nCuerpo'),
      'Título\nCuerpo',
    );
  });

  test('markdownAPlano en nota serializada usa solo el cuerpo', () {
    const nota = NotaSerializada(
      estilo: EstiloNota(fondo: 'pastelVerde'),
      cuerpo: '**Hola** mundo',
    );
    final linea = NotaSerializada.markdownAPlano(
      NotaSerializada.parse(nota.serializar()).cuerpo,
    );
    expect(linea, 'Hola mundo');
  });

  test('serializa y parsea metadatos', () {
    const original = NotaSerializada(
      estilo: EstiloNota(fondo: 'pastelRosa', fuente: 'playfair'),
      cuerpo: '# Título\nCuerpo',
    );
    final texto = original.serializar();
    final otra = NotaSerializada.parse(texto);
    expect(otra.cuerpo, original.cuerpo);
    expect(otra.estilo.fondo, 'pastelRosa');
    expect(otra.estilo.fuente, 'playfair');
  });
}
