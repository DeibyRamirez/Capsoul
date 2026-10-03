import 'package:capsoul/funcionalidades/elementos/dominio/elemento_borrador.dart';
import 'package:capsoul/funcionalidades/elementos/dominio/tipo_elemento.dart';
import 'package:capsoul/funcionalidades/elementos/presentacion/pantalla_escribir_nota.dart';
import 'package:capsoul/nucleo/tema/tema_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Resultado {
  ElementoBorrador? nota;
  bool terminado = false;
}

/// Abre la pantalla de nota sobre una ruta base y guarda lo que devuelve.
Future<_Resultado> _abrirNota(WidgetTester tester) async {
  final resultado = _Resultado();
  await tester.pumpWidget(
    MaterialApp(
      theme: TemaApp.claro,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async {
              resultado.nota = await Navigator.of(context).push<ElementoBorrador>(
                MaterialPageRoute(builder: (_) => const PantallaEscribirNota()),
              );
              resultado.terminado = true;
            },
            child: const Text('abrir'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
  return resultado;
}

void main() {
  testWidgets('cuenta caracteres y devuelve la nota', (tester) async {
    final resultado = await _abrirNota(tester);

    expect(find.text('0 / 5000'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('campo-nota')), '  Te quiero  ');
    await tester.pump();
    expect(find.text('13 / 5000'), findsOneWidget);

    await tester.tap(find.text('Guardar nota'));
    await tester.pumpAndSettle();

    expect(resultado.terminado, isTrue);
    final nota = resultado.nota;
    expect(nota?.tipo, TipoElemento.texto);
    expect(nota?.texto, 'Te quiero');
    expect(nota?.bytes, 9);
  });

  testWidgets('no deja guardar una nota vacía', (tester) async {
    await _abrirNota(tester);

    await tester.tap(find.text('Guardar nota'));
    await tester.pump();

    expect(find.text('Escribe algo antes de guardar la nota.'), findsOneWidget);
    expect(find.byType(PantallaEscribirNota), findsOneWidget);
  });

  testWidgets('corta el texto en 5000 caracteres', (tester) async {
    await _abrirNota(tester);

    await tester.enterText(find.byKey(const Key('campo-nota')), 'a' * 5003);
    await tester.pump();

    expect(find.text('5000 / 5000'), findsOneWidget);
  });
}
