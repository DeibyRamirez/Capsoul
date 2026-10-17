import 'package:capsoul/funcionalidades/elementos/dominio/tipo_elemento.dart';
import 'package:capsoul/funcionalidades/elementos/presentacion/componentes/hoja_origen_medio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('hoja de origen ofrece capturar y dispositivo para foto', (tester) async {
    OrigenMedio? elegido;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                elegido = await mostrarHojaOrigenMedio(context, TipoElemento.foto);
              },
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Elegir de la galería'), findsOneWidget);
    await tester.tap(find.text('Elegir de la galería'));
    await tester.pumpAndSettle();

    expect(elegido, OrigenMedio.dispositivo);
  });
}
