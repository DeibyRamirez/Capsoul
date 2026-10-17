import 'package:capsoul/funcionalidades/elementos/dominio/nota_serializada.dart';
import 'package:capsoul/funcionalidades/recuerdos/presentacion/componentes/vista_nota_compacta.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('miniatura 56x56 con nota larga no hace overflow', (tester) async {
    final cuerpoLargo = List.filled(40, 'Línea de texto larga.').join('\n');
    final nota = NotaSerializada(
      estilo: const EstiloNota(fondo: 'pastelVerde'),
      cuerpo: cuerpoLargo,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox.square(
            dimension: 56,
            child: VistaNotaCompacta(
              contenidoTexto: nota.serializar(),
              rellenar: true,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(MarkdownBody), findsNothing);
  });

  testWidgets('preview amplio usa markdown con scroll', (tester) async {
    const nota = NotaSerializada(
      estilo: EstiloNota(fondo: 'pastelAzul'),
      cuerpo: '**Título**\n\nPárrafo visible.',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AspectRatio(
            aspectRatio: 4 / 3,
            child: VistaNotaCompacta(
              contenidoTexto: nota.serializar(),
              rellenar: false,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(MarkdownBody), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });
}
