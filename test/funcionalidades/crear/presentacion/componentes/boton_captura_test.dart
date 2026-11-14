import 'package:capsoul/funcionalidades/crear/dominio/modo_captura.dart';
import 'package:capsoul/funcionalidades/crear/presentacion/componentes/boton_captura.dart';
import 'package:capsoul/funcionalidades/crear/presentacion/tema/tokens_crear.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _montar(
  WidgetTester tester, {
  required ModoCaptura modo,
  required bool grabando,
  double progreso = 0,
  VoidCallback? alTap,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: BotonCaptura(
            modo: modo,
            grabando: grabando,
            progreso: ValueNotifier<double>(progreso),
            alTap: alTap,
          ),
        ),
      ),
    ),
  );
}

BoxDecoration _decoracionCentro(WidgetTester tester) {
  final centro = tester.widget<AnimatedContainer>(
    find.byKey(const Key('centro-boton-captura')),
  );
  return centro.decoration! as BoxDecoration;
}

void main() {
  const tokens = TokensCrear.claro;

  testWidgets('en reposo el centro es un círculo dentro del anillo', (tester) async {
    await _montar(tester, modo: ModoCaptura.video, grabando: false);
    await tester.pumpAndSettle();

    final centro = tester.getSize(find.byKey(const Key('centro-boton-captura')));
    expect(centro.width, centro.height);
    // No toca el anillo: queda aire entre el trazo y el centro.
    expect(centro.width, lessThan(tokens.tamanoBotonCaptura - 2 * tokens.grosorAnillo));
    final radio = _decoracionCentro(tester).borderRadius! as BorderRadius;
    expect(radio.topLeft.x, centro.width / 2);
    expect(find.bySemanticsLabel('Iniciar grabación'), findsOneWidget);
  });

  testWidgets('al grabar pasa a un cuadrado redondeado rojo, pequeño y centrado',
      (tester) async {
    await _montar(tester, modo: ModoCaptura.video, grabando: false);
    await tester.pumpAndSettle();
    final antes = tester.getSize(find.byKey(const Key('centro-boton-captura')));

    await _montar(tester, modo: ModoCaptura.video, grabando: true, progreso: 0.3);
    await tester.pump(const Duration(milliseconds: 120));
    final aMitad = tester.getSize(find.byKey(const Key('centro-boton-captura')));
    // La transición es animada, no un salto.
    expect(aMitad.width, lessThan(antes.width));
    await tester.pumpAndSettle();

    final lado = tokens.tamanoBotonCaptura * BotonCaptura.proporcionCuadrado;
    final centro = tester.getSize(find.byKey(const Key('centro-boton-captura')));
    expect(centro, Size.square(lado));
    expect(aMitad.width, greaterThan(lado));
    final decoracion = _decoracionCentro(tester);
    final radio = decoracion.borderRadius! as BorderRadius;
    expect(radio.topLeft.x, lado * BotonCaptura.proporcionEsquinas);
    expect(radio.topLeft.x, lessThan(lado / 2));
    final contexto = tester.element(find.byType(BotonCaptura));
    expect(decoracion.color, Theme.of(contexto).colorScheme.error);

    // Centrado dentro del botón y sin salirse de sus límites.
    final boton = tester.getRect(find.byKey(const Key('boton-captura')));
    final rectCentro = tester.getRect(find.byKey(const Key('centro-boton-captura')));
    expect(rectCentro.center, boton.center);
    expect(boton.contains(rectCentro.topLeft), isTrue);
    expect(boton.size, Size.square(tokens.tamanoBotonCaptura));
    expect(find.bySemanticsLabel('Pausar grabación'), findsOneWidget);
  });

  testWidgets('en foto el centro es blanco y no cambia de forma', (tester) async {
    var toques = 0;
    await _montar(
      tester,
      modo: ModoCaptura.foto,
      grabando: true,
      alTap: () => toques++,
    );
    await tester.pumpAndSettle();

    final centro = tester.getSize(find.byKey(const Key('centro-boton-captura')));
    final radio = _decoracionCentro(tester).borderRadius! as BorderRadius;
    expect(radio.topLeft.x, centro.width / 2);
    expect(_decoracionCentro(tester).color, tokens.sobreMarca);

    await tester.tap(find.byType(BotonCaptura));
    expect(toques, 1);
  });
}