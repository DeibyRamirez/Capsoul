import 'package:capsoul/funcionalidades/elementos/dominio/tipo_elemento.dart';
import 'package:capsoul/funcionalidades/momentos/dominio/nuevo_momento.dart';
import 'package:capsoul/funcionalidades/momentos/presentacion/componentes/rejilla_bento.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../ayudantes/app_prueba.dart';
import '../../../ayudantes/falsos.dart';
import '../../../ayudantes/falsos_momentos.dart';
import '../../../ayudantes/falsos_recuerdos.dart';

Future<void> _abrirMomentos(WidgetTester tester) async {
  await tester.tap(find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text('Momentos'),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('crea un momento con todos los recuerdos y abre su detalle',
      (tester) async {
    final momentos = RepositorioMomentosFalso();
    await montarAppCapsoul(
      tester,
      autenticacion: RepositorioAutenticacionFalso(usuarioInicial: usuarioPrueba),
      momentos: momentos,
      recuerdos: RepositorioRecuerdosFalso(iniciales: [
        recuerdoPrueba('f1', titulo: 'Playa'),
        recuerdoPrueba('n1', tipo: TipoElemento.texto, texto: 'Querido diario'),
      ]),
    );

    // Selector "+" → Momento.
    await tester.tap(find.text('Guardar algo hoy'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Momento'));
    await tester.pumpAndSettle();
    expect(find.text('Nuevo momento'), findsOneWidget);

    final agregar = find.byKey(const Key('boton-agregar-filtro'));
    await tester.ensureVisible(agregar);
    await tester.pumpAndSettle();
    await tester.tap(agregar);
    await tester.pumpAndSettle();
    expect(find.text('Recuerdos (2/60)'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    // Paso 2: nombre del momento.
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('campo-nombre-momento')),
      'Vacaciones',
    );

    // Paso 3: la primera foto queda como portada.
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    final desplazable = find
        .descendant(
          of: find
              .descendant(of: find.byType(PageView), matching: find.byType(ListView))
              .first,
          matching: find.byType(Scrollable),
        )
        .first;
    final portada = find.byKey(const ValueKey('portada-f1'));
    await tester.scrollUntilVisible(portada, 200, scrollable: desplazable);
    expect(portada, findsOneWidget);

    await tester.tap(find.text('Guardar momento'));
    await tester.pumpAndSettle();

    final creado = momentos.creados.single;
    expect(creado.titulo, 'Vacaciones');
    expect(creado.portadaId, 'f1');
    expect(creado.recuerdos.map((r) => r.id), containsAll(['f1', 'n1']));
    expect(find.text('Vacaciones'), findsOneWidget);
    expect(find.byType(RejillaBento), findsOneWidget);
  });

  testWidgets('la pestaña lista los momentos y borra con confirmación',
      (tester) async {
    final momentos = RepositorioMomentosFalso();
    await montarAppCapsoul(
      tester,
      autenticacion: RepositorioAutenticacionFalso(usuarioInicial: usuarioPrueba),
      momentos: momentos,
    );
    await momentos.crear(
      NuevoMomento(titulo: 'Viaje', recuerdos: [recuerdoPrueba('f1')]),
    );
    await _abrirMomentos(tester);
    expect(find.text('Viaje'), findsOneWidget);
    expect(find.text('1 recuerdo · 3 oct 2026'), findsOneWidget);

    await tester.tap(find.text('Viaje'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('menu-acciones-ancla')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Borrar momento').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Borrar'));
    await tester.pumpAndSettle();

    expect(momentos.eliminados, ['momento-1']);
    expect(find.textContaining('Aún no tienes momentos'), findsOneWidget);
  });
}
