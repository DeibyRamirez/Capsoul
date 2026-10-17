import 'package:capsoul/nucleo/componentes/encabezado_seccion_capsoul.dart';
import 'package:capsoul/nucleo/tema/tema_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra marca, título, subtítulo e icono', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: TemaApp.claro,
        home: const Scaffold(
          body: EncabezadoSeccionCapsoul(
            titulo: 'Momentos',
            subtitulo: 'Tus recuerdos, tu historia.',
            icono: Icons.local_florist_outlined,
          ),
        ),
      ),
    );

    expect(find.text('cápsoul'), findsOneWidget);
    expect(find.text('Momentos'), findsOneWidget);
    expect(find.text('Tus recuerdos, tu historia.'), findsOneWidget);
    expect(find.byIcon(Icons.local_florist_outlined), findsOneWidget);
  });
}
