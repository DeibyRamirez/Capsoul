import 'package:capsoul/funcionalidades/capsulas/dominio/fallo_capsula.dart';
import 'package:capsoul/funcionalidades/capsulas/presentacion/componentes/botones_agregar_elemento.dart';
import 'package:capsoul/funcionalidades/elementos/dominio/tipo_elemento.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../ayudantes/app_prueba.dart';
import '../../../ayudantes/falsos.dart';
import '../../../ayudantes/falsos_capsulas.dart';

Future<void> _abrirNuevaCapsula(WidgetTester tester) async {
  await tester.tap(find.text('Guardar algo hoy'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Cápsula del tiempo'));
  await tester.pumpAndSettle();
}

/// Lista del formulario (los TextField tienen su propio Scrollable).
Finder _listaFormulario() => find
    .descendant(
      of: find.byKey(const Key('formulario-capsula')),
      matching: find.byType(Scrollable),
    )
    .first;

Future<void> _agregarNota(WidgetTester tester, String texto) async {
  await tester.tap(
    find.descendant(
      of: find.byType(BotonesAgregarElemento),
      matching: find.text('Nota'),
    ),
  );
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('campo-nota')), texto);
  await tester.tap(find.text('Guardar nota'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('el formulario tiene destinatario deshabilitado (Próximamente)',
      (tester) async {
    await montarAppCapsoul(
      tester,
      autenticacion: RepositorioAutenticacionFalso(usuarioInicial: usuarioPrueba),
    );
    await _abrirNuevaCapsula(tester);

    expect(find.text('Nueva cápsula'), findsOneWidget);
    expect(find.text('Recuerdos (0/10)'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Destinatario'), 200, scrollable: _listaFormulario());
    final destinatario = tester.widget<TextField>(
      find.byKey(const Key('campo-destinatario')),
    );
    expect(destinatario.enabled, isFalse);
    expect(find.text('Próximamente'), findsOneWidget);
  });

  testWidgets('no guarda sin fecha de apertura y lo explica', (tester) async {
    await montarAppCapsoul(
      tester,
      autenticacion: RepositorioAutenticacionFalso(usuarioInicial: usuarioPrueba),
    );
    await _abrirNuevaCapsula(tester);
    await tester.scrollUntilVisible(find.text('Guardar cápsula'), 200, scrollable: _listaFormulario());
    await tester.tap(find.text('Guardar cápsula'));
    await tester.pump();

    expect(find.text('Elige una fecha de apertura en el futuro.'), findsOneWidget);
  });

  testWidgets('agrega una nota, la quita y guarda la cápsula', (tester) async {
    final capsulas = RepositorioCapsulasFalso();
    await montarAppCapsoul(
      tester,
      autenticacion: RepositorioAutenticacionFalso(usuarioInicial: usuarioPrueba),
      capsulas: capsulas,
    );
    await _abrirNuevaCapsula(tester);

    await _agregarNota(tester, 'Primera');
    await _agregarNota(tester, 'Te quiero, Jacobo');
    expect(find.text('Recuerdos (2/10)'), findsOneWidget);
    await tester.tap(find.byTooltip('Quitar').first);
    await tester.pumpAndSettle();
    expect(find.text('Recuerdos (1/10)'), findsOneWidget);
    expect(find.text('Primera'), findsNothing);

    await tester.enterText(find.byKey(const Key('campo-titulo')), 'Para Jacobo');
    await tester.enterText(find.byKey(const Key('campo-mensaje')), 'Ábrela grande');
    await tester.scrollUntilVisible(find.byKey(const Key('campo-fecha')), 200, scrollable: _listaFormulario());
    await tester.tap(find.byKey(const Key('campo-fecha')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Elegir'));
    await tester.pumpAndSettle();
    expect(find.text('Se abrirá el 3 oct 2027'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Guardar cápsula'), 200, scrollable: _listaFormulario());
    await tester.tap(find.text('Guardar cápsula'));
    await tester.pumpAndSettle();

    final nueva = capsulas.creadas.single;
    expect(nueva.titulo, 'Para Jacobo');
    expect(nueva.mensaje, 'Ábrela grande');
    expect(nueva.fechaApertura, DateTime(2027, 10, 3, 8));
    expect(nueva.elementos.single.tipo, TipoElemento.texto);
    expect(nueva.elementos.single.texto, 'Te quiero, Jacobo');
    // Tras guardar abre el detalle.
    expect(find.text('Abrir en'), findsOneWidget);
    expect(find.text('Para Jacobo'), findsOneWidget);
  });

  testWidgets('muestra el fallo del repositorio en español', (tester) async {
    final capsulas = RepositorioCapsulasFalso()
      ..siguienteFallo = const FalloCapsula.sinRed();
    await montarAppCapsoul(
      tester,
      autenticacion: RepositorioAutenticacionFalso(usuarioInicial: usuarioPrueba),
      capsulas: capsulas,
    );
    await _abrirNuevaCapsula(tester);
    await _agregarNota(tester, 'Hola');
    await tester.enterText(find.byKey(const Key('campo-titulo')), 'Para mí');
    await tester.scrollUntilVisible(find.byKey(const Key('campo-fecha')), 200, scrollable: _listaFormulario());
    await tester.tap(find.byKey(const Key('campo-fecha')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Elegir'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Guardar cápsula'), 200, scrollable: _listaFormulario());
    await tester.tap(find.text('Guardar cápsula'));
    await tester.pumpAndSettle();

    expect(
      find.text('Sin conexión. Revisa tu internet e inténtalo de nuevo.'),
      findsOneWidget,
    );
    expect(find.text('Nueva cápsula'), findsOneWidget);
  });
}
