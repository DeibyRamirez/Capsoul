import 'package:capsoul/funcionalidades/elementos/dominio/elemento_borrador.dart';
import 'package:capsoul/funcionalidades/elementos/dominio/nota_delta.dart';
import 'package:capsoul/funcionalidades/elementos/dominio/nota_serializada.dart';
import 'package:capsoul/funcionalidades/elementos/dominio/tipo_elemento.dart';
import 'package:capsoul/funcionalidades/elementos/presentacion/pantalla_escribir_nota.dart';
import 'package:capsoul/nucleo/tema/tema_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _Resultado {
  ElementoBorrador? nota;
  bool terminado = false;
}

/// Abre la pantalla de nota sobre una ruta base y guarda lo que devuelve.
Future<_Resultado> _abrirNota(WidgetTester tester) async {
  final resultado = _Resultado();
  final enrutador = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: TextButton(
            onPressed: () async {
              resultado.nota = await context.push<ElementoBorrador>('/nota');
              resultado.terminado = true;
            },
            child: const Text('abrir'),
          ),
        ),
        routes: [
          GoRoute(
            path: 'nota',
            builder: (context, state) => const PantallaEscribirNota(),
          ),
        ],
      ),
    ],
  );
  await tester.pumpWidget(
    MaterialApp.router(
      theme: TemaApp.claro,
      locale: const Locale('es'),
      supportedLocales: const [Locale('es')],
      localizationsDelegates: const [
        ...GlobalMaterialLocalizations.delegates,
        quill.FlutterQuillLocalizations.delegate,
      ],
      routerConfig: enrutador,
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
  return resultado;
}

quill.QuillController _controlador(WidgetTester tester) {
  final editor = tester.widget<quill.QuillEditor>(
    find.byKey(const Key('campo-nota')),
  );
  return editor.controller;
}

void main() {
  testWidgets('cuenta caracteres y devuelve la nota enriquecida', (
    tester,
  ) async {
    final resultado = await _abrirNota(tester);
    final controlador = _controlador(tester);

    expect(find.text('0 / 5000'), findsOneWidget);
    controlador.replaceText(
      0,
      0,
      '  Te quiero  ',
      const TextSelection.collapsed(offset: 13),
    );
    await tester.pump();
    expect(find.text('13 / 5000'), findsOneWidget);

    await tester.tap(find.byKey(const Key('guardar-nota')));
    await tester.pumpAndSettle();

    expect(resultado.terminado, isTrue);
    final nota = resultado.nota;
    expect(nota?.tipo, TipoElemento.texto);
    final serializada = NotaSerializada.parse(nota?.texto);
    expect(serializada.cuerpo, 'Te quiero');
    expect(serializada.esRica, isTrue);
    expect(textoPlanoDesdeDelta(serializada.delta!).trim(), 'Te quiero');
    expect(nota?.bytes, nota!.texto!.length);
  });

  testWidgets('deshabilita guardar mientras la nota esté vacía', (
    tester,
  ) async {
    await _abrirNota(tester);

    final boton = tester.widget<TextButton>(
      find.byKey(const Key('guardar-nota')),
    );
    expect(boton.onPressed, isNull);
    expect(find.byType(PantallaEscribirNota), findsOneWidget);
  });

  testWidgets('no deja superar los 5000 caracteres', (tester) async {
    await _abrirNota(tester);
    final controlador = _controlador(tester);

    controlador.replaceText(
      0,
      0,
      'a' * 5000,
      const TextSelection.collapsed(offset: 5000),
    );
    await tester.pump();
    expect(find.text('5000 / 5000'), findsOneWidget);

    controlador.replaceText(
      5000,
      0,
      'b',
      const TextSelection.collapsed(offset: 5001),
    );
    await tester.pump();

    expect(find.text('5000 / 5000'), findsOneWidget);
    expect(controlador.document.toPlainText(), '${'a' * 5000}\n');
  });

  testWidgets('el teclado deja visible el editor y la barra de formato', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    await _abrirNota(tester);
    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final campo = find.byKey(const Key('campo-nota'));
    expect(campo, findsOneWidget);
    expect(tester.getSize(campo).height, greaterThan(80));
    expect(tester.getBottomLeft(campo).dy, lessThanOrEqualTo(844 - 320));

    expect(find.byKey(const Key('formato-negrita')), findsOneWidget);
    expect(find.text('0 / 5000'), findsOneWidget);
    expect(find.byKey(const Key('guardar-nota')), findsOneWidget);

    tester.view.viewInsets = FakeViewPadding.zero;
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('formato-negrita')), findsOneWidget);
  });

  testWidgets('cambia color y tipografía desde la hoja de estilo', (
    tester,
  ) async {
    final resultado = await _abrirNota(tester);

    await tester.tap(find.byKey(const Key('estilo-nota')));
    await tester.pumpAndSettle();
    expect(find.text('Estilo de la nota'), findsOneWidget);
    expect(find.text('Poppins'), findsOneWidget);
    expect(find.text('Playfair'), findsOneWidget);
    expect(find.text('Azul'), findsOneWidget);

    await tester.tap(find.byKey(const Key('color-pastelRosa')));
    await tester.tap(find.text('Playfair'));
    await tester.pump();
    await tester.tap(find.text('Aplicar estilo'));
    await tester.pumpAndSettle();
    expect(find.text('Estilo de la nota'), findsNothing);

    final controlador = _controlador(tester);
    controlador.replaceText(
      0,
      0,
      'Hola',
      const TextSelection.collapsed(offset: 4),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('guardar-nota')));
    await tester.pumpAndSettle();

    final nota = NotaSerializada.parse(resultado.nota?.texto);
    expect(nota.estilo.fondo, 'pastelRosa');
    expect(nota.estilo.fuente, 'playfair');
  });

  testWidgets('aplica negrita, cursiva y subrayado sin símbolos visibles', (
    tester,
  ) async {
    await _abrirNota(tester);
    final controlador = _controlador(tester);

    controlador.replaceText(
      0,
      0,
      'Hola mundo',
      const TextSelection.collapsed(offset: 10),
    );
    controlador.updateSelection(
      const TextSelection(baseOffset: 0, extentOffset: 4),
      quill.ChangeSource.local,
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('formato-negrita')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('formato-cursiva')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('formato-subrayado')));
    await tester.pump();

    final delta = controlador.document.toDelta().toJson();
    final hola = delta.firstWhere((op) => op['insert'] == 'Hola');
    final atributos = hola['attributes'] as Map;
    expect(atributos['bold'], isTrue);
    expect(atributos['italic'], isTrue);
    expect(atributos['underline'], isTrue);
    expect(controlador.document.toPlainText(), 'Hola mundo\n');
    expect(controlador.document.toPlainText(), isNot(contains('**')));

    await tester.tap(find.byKey(const Key('formato-normal')));
    await tester.pump();
    final limpio = controlador.document.toDelta().toJson();
    expect(limpio.every((op) => op['attributes'] == null), isTrue);
  });
}
