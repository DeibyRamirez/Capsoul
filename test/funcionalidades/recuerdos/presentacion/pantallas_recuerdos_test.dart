import 'package:capsoul/funcionalidades/elementos/dominio/tipo_elemento.dart';
import 'package:capsoul/funcionalidades/recuerdos/dominio/recuerdo.dart';
import 'package:capsoul/funcionalidades/recuerdos/presentacion/pantalla_elegir_recuerdos.dart';
import 'package:capsoul/nucleo/enrutador/rutas_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../ayudantes/app_prueba.dart';
import '../../../ayudantes/falsos.dart';
import '../../../ayudantes/falsos_recuerdos.dart';

Future<RepositorioRecuerdosFalso> _montar(
  WidgetTester tester, {
  List<Recuerdo> iniciales = const [],
}) async {
  final recuerdos = RepositorioRecuerdosFalso(iniciales: iniciales);
  await montarAppCapsoul(
    tester,
    autenticacion: RepositorioAutenticacionFalso(usuarioInicial: usuarioPrueba),
    recuerdos: recuerdos,
  );
  return recuerdos;
}

Future<void> _abrirRecuerdos(WidgetTester tester) async {
  await tester.tap(find.text('Tu banco de recuerdos.'));
  await tester.pumpAndSettle();
}

GoRouter _enrutador(WidgetTester tester) =>
    GoRouter.of(tester.element(find.byType(Navigator).first));

void main() {
  testWidgets('Inicio abre el banco de recuerdos vacío', (tester) async {
    await _montar(tester);
    await _abrirRecuerdos(tester);

    expect(find.text('Tu banco de recuerdos'), findsOneWidget);
    expect(find.textContaining('Aún no tienes recuerdos'), findsOneWidget);
    expect(find.text('Nuevo recuerdo'), findsOneWidget);
  });

  testWidgets('lista recuerdos y filtra por tipo', (tester) async {
    await _montar(tester, iniciales: [
      recuerdoPrueba('f1', titulo: 'Playa'),
      recuerdoPrueba('n1', tipo: TipoElemento.texto, texto: 'Querida abuela'),
    ]);
    await _abrirRecuerdos(tester);

    expect(find.text('Playa'), findsOneWidget);
    // La nota aparece en la miniatura y como nombre.
    expect(find.text('Querida abuela'), findsWidgets);

    final chipNotas = find.widgetWithText(FilterChip, 'Notas');
    await tester.ensureVisible(chipNotas);
    await tester.pumpAndSettle();
    await tester.tap(chipNotas);
    await tester.pumpAndSettle();
    expect(find.text('Playa'), findsNothing);
    expect(find.text('Querida abuela'), findsWidgets);
  });

  testWidgets('escribir una nota la guarda con título y fecha', (tester) async {
    final recuerdos = await _montar(tester);
    await _abrirRecuerdos(tester);

    await tester.tap(find.text('Nuevo recuerdo'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Nota'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('campo-nota')), 'Hola futuro');
    await tester.tap(find.text('Guardar nota'));
    await tester.pumpAndSettle();

    expect(find.text('Guardar recuerdo'), findsWidgets);
    await tester.enterText(
      find.byKey(const Key('campo-titulo-recuerdo')),
      'Carta',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar recuerdo'));
    await tester.pumpAndSettle();

    final creado = recuerdos.creados.single;
    expect(creado.titulo, 'Carta');
    expect(creado.fechaRecuerdo, DateTime(2026, 10, 3));
    expect(creado.elemento.texto, 'Hola futuro');
    // Vuelve al banco, que ya muestra el recuerdo.
    expect(find.text('Tu banco de recuerdos'), findsOneWidget);
    expect(find.text('Carta'), findsOneWidget);
  });

  testWidgets('no deja borrar un recuerdo que está en una cápsula sellada',
      (tester) async {
    final recuerdos = await _montar(tester, iniciales: [
      recuerdoPrueba('f1', titulo: 'Playa', propietarioId: usuarioPrueba.uid),
    ])
      ..selladas['f1'] = 1;
    await _abrirRecuerdos(tester);
    await tester.tap(find.text('Playa'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('boton-borrar-recuerdo')));
    await tester.pumpAndSettle();

    expect(find.text('No se puede borrar'), findsOneWidget);
    await tester.tap(find.text('Entendido'));
    await tester.pumpAndSettle();
    expect(recuerdos.eliminados, isEmpty);
  });

  testWidgets('borra un recuerdo libre tras confirmar', (tester) async {
    final recuerdos = await _montar(tester, iniciales: [
      recuerdoPrueba('f1', titulo: 'Playa', propietarioId: usuarioPrueba.uid),
    ]);
    await _abrirRecuerdos(tester);
    await tester.tap(find.text('Playa'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('boton-borrar-recuerdo')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Borrar'));
    await tester.pumpAndSettle();

    expect(recuerdos.eliminados, ['f1']);
    expect(find.text('Playa'), findsNothing);
  });

  testWidgets('elegir recuerdos devuelve la selección sin los ya elegidos',
      (tester) async {
    await _montar(tester, iniciales: [
      recuerdoPrueba('a', titulo: 'Uno'),
      recuerdoPrueba('b', titulo: 'Dos'),
      recuerdoPrueba('c', titulo: 'Tres'),
    ]);
    List<Recuerdo>? elegidos;
    _enrutador(tester)
        .push<List<Recuerdo>>(
          RutasApp.elegirRecuerdos,
          extra: const ParametrosElegirRecuerdos(yaElegidos: {'c'}, maximo: 1),
        )
        .then((lista) => elegidos = lista);
    await tester.pumpAndSettle();

    expect(find.text('Tres'), findsNothing);
    await tester.tap(find.text('Uno'));
    await tester.pump();
    await tester.tap(find.text('Dos'));
    await tester.pump();
    expect(find.text('Puedes elegir 1 recuerdo.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('boton-listo-elegir')));
    await tester.pumpAndSettle();
    expect(elegidos?.map((r) => r.id), ['a']);
  });
}
