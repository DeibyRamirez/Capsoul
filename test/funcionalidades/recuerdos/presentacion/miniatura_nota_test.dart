import 'package:capsoul/funcionalidades/elementos/dominio/nota_serializada.dart';
import 'package:capsoul/funcionalidades/elementos/dominio/tipo_elemento.dart';
import 'package:capsoul/funcionalidades/recuerdos/dominio/recuerdo.dart';
import 'package:capsoul/funcionalidades/recuerdos/presentacion/componentes/miniatura_recuerdo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Recuerdo.nombre sin titulo quita negrilla de la primera linea', () {
    const nota = NotaSerializada(
      estilo: EstiloNota(fondo: 'pastelVerde'),
      cuerpo: '**Exotiqueo**\nMas texto',
    );
    final recuerdo = Recuerdo(
      id: 'n1',
      propietarioId: 'u1',
      tipo: TipoElemento.texto,
      fechaRecuerdo: DateTime(2026, 10, 16),
      creadoEn: DateTime(2026, 10, 16),
      contenidoTexto: nota.serializar(),
    );
    expect(recuerdo.nombre, 'Exotiqueo');
  });

  test('Recuerdo.nota lee el contenido enriquecido de la fila', () {
    final nota = NotaSerializada(
      estilo: const EstiloNota(fondo: 'pastelAzul'),
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
    final recuerdo = Recuerdo(
      id: 'n2',
      propietarioId: 'u1',
      tipo: TipoElemento.texto,
      fechaRecuerdo: DateTime(2026, 10, 16),
      creadoEn: DateTime(2026, 10, 16),
      contenidoTexto: 'Hola mundo',
      contenidoRico: nota.contenidoRico,
    );

    expect(recuerdo.nota.esRica, isTrue);
    expect(recuerdo.nota.cuerpo, 'Hola mundo');
  });

  testWidgets(
    'MiniaturaRecuerdo nota no muestra front matter ni ** literales',
    (tester) async {
      const nota = NotaSerializada(
        estilo: EstiloNota(fondo: 'pastelVerde'),
        cuerpo: '**Exotiqueo**',
      );
      final recuerdo = Recuerdo(
        id: 'n1',
        propietarioId: 'u1',
        tipo: TipoElemento.texto,
        fechaRecuerdo: DateTime(2026, 10, 16),
        creadoEn: DateTime(2026, 10, 16),
        contenidoTexto: nota.serializar(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 200,
              child: MiniaturaRecuerdo(recuerdo: recuerdo),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Exotiqueo'), findsOneWidget);
      expect(find.textContaining('---capsoul'), findsNothing);
      expect(find.text('**Exotiqueo**'), findsNothing);
    },
  );
}
