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

  testWidgets('MiniaturaRecuerdo nota no muestra front matter ni ** literales',
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
  });
}
