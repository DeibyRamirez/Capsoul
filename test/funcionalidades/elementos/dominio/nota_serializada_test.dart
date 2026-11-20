import 'package:capsoul/funcionalidades/elementos/dominio/nota_delta.dart';
import 'package:capsoul/funcionalidades/elementos/dominio/nota_serializada.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('texto legacy sin front matter', () {
    final nota = NotaSerializada.parse('Hola **mundo**');
    expect(nota.cuerpo, 'Hola **mundo**');
    expect(nota.estilo.fondo, 'pastelAzul');
    expect(nota.esRica, isFalse);
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
    expect(otra.esRica, isFalse);
  });

  test('parsea el payload que devuelve la pantalla de nota', () {
    const almacenado =
        '---capsoul\n'
        '{"v":2,"fondo":"pastelAzul","fuente":"poppins","delta":'
        '[{"insert":"  Te quiero  \\n"}]}\n'
        '---\n'
        'Te quiero';
    final nota = NotaSerializada.parse(almacenado);
    expect(nota.cuerpo, 'Te quiero');
    expect(nota.esRica, isTrue);
  });

  test('serializa y parsea una nota enriquecida', () {
    final nota = NotaSerializada(
      estilo: const EstiloNota(fondo: 'pastelVerde', fuente: 'poppins'),
      cuerpo: 'Hola mundo',
      delta: [
        {'insert': 'Hola '},
        {
          'insert': 'mundo',
          'attributes': {'bold': true},
        },
        {'insert': '\n'},
      ],
    );

    final parseada = NotaSerializada.parse(nota.serializar());
    expect(parseada.cuerpo, 'Hola mundo');
    expect(parseada.esRica, isTrue);
    expect(textoPlanoDesdeDelta(parseada.delta!), 'Hola mundo');
    expect(parseada.estilo.fondo, 'pastelVerde');
    expect(parseada.contenidoRico?['version'], 1);
  });

  test('desdeColumnas prefiere el contenido rico', () {
    final nota = NotaSerializada.desdeColumnas(
      contenidoTexto: 'Hola mundo',
      contenidoRico: {
        'version': 1,
        'estilo': {'fondo': 'pastelRosa', 'fuente': 'playfair'},
        'delta': [
          {'insert': 'Hola '},
          {
            'insert': 'mundo',
            'attributes': {'bold': true},
          },
          {'insert': '\n'},
        ],
      },
    );

    expect(nota.esRica, isTrue);
    expect(nota.cuerpo, 'Hola mundo');
    expect(nota.estilo.fondo, 'pastelRosa');
    expect(nota.estilo.fuente, 'playfair');
    expect(nota.aColumnas()['contenido_texto'], 'Hola mundo');
  });

  test('convierte el Markdown legacy a Delta sin perder formatos', () {
    final delta = deltaDesdeMarkdownLegacy('Hola **mundo** y <u>tú</u>');

    expect(textoPlanoDesdeDelta(delta), 'Hola mundo y tú');
    expect(
      delta.any((op) => (op['attributes'] as Map?)?['bold'] == true),
      isTrue,
    );
    expect(
      delta.any((op) => (op['attributes'] as Map?)?['underline'] == true),
      isTrue,
    );
  });

  test('sanitiza atributos externos y garantiza el salto final', () {
    final delta = sanitizarDelta([
      {
        'insert': 'Hola',
        'attributes': {'bold': true, 'link': 'https://x'},
      },
      {
        'insert': ' mundo',
        'attributes': {'italic': true},
      },
    ]);

    expect(textoPlanoDesdeDelta(delta), 'Hola mundo');
    expect(delta.last['insert'], endsWith('\n'));
    expect(
      delta.any((op) => (op['attributes'] as Map?)?['link'] != null),
      isFalse,
    );
  });
}
