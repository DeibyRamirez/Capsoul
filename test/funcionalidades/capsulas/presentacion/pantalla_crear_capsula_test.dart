import 'package:capsoul/funcionalidades/capsulas/dominio/fallo_capsula.dart';
import 'package:capsoul/funcionalidades/capsulas/presentacion/componentes/botones_agregar_elemento.dart';
import 'package:capsoul/funcionalidades/elementos/dominio/tipo_elemento.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../ayudantes/app_prueba.dart';
import '../../../ayudantes/falsos.dart';
import '../../../ayudantes/falsos_capsulas.dart';
import '../../../ayudantes/falsos_recuerdos.dart';

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

/// Hace visible [objetivo] dentro del formulario y lo toca.
Future<void> _tocar(WidgetTester tester, Finder objetivo) async {
  await tester.scrollUntilVisible(objetivo, 200, scrollable: _listaFormulario());
  await tester.ensureVisible(objetivo);
  await tester.pumpAndSettle();
  await tester.tap(objetivo);
}

Future<void> _agregarNota(WidgetTester tester, String texto) async {
  await _tocar(
    tester,
    find.descendant(
      of: find.byType(BotonesAgregarElemento),
      matching: find.text('Nota'),
    ),
  );
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('campo-nota')), texto);
  await tester.tap(find.text('Guardar nota'));
  await tester.pumpAndSettle();
  // Se guarda en el banco de recuerdos y vuelve a la cápsula.
  await tester.tap(find.widgetWithText(FilledButton, 'Guardar recuerdo'));
  await tester.pumpAndSettle();
  // Deja que se oculte el aviso "Guardado en tus recuerdos.".
  await tester.pump(const Duration(seconds: 5));
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
    await _tocar(tester, find.text('Guardar cápsula'));
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
    await _tocar(tester, find.byTooltip('Quitar').first);
    await tester.pumpAndSettle();
    expect(find.text('Recuerdos (1/10)'), findsOneWidget);
    expect(find.text('Primera'), findsNothing);

    await tester.enterText(find.byKey(const Key('campo-titulo')), 'Para Jacobo');
    await tester.enterText(find.byKey(const Key('campo-mensaje')), 'Ábrela grande');
    await _tocar(tester, find.byKey(const Key('campo-fecha')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Elegir'));
    await tester.pumpAndSettle();
    expect(find.text('Se abrirá el 3 oct 2027'), findsOneWidget);

    await _tocar(tester, find.text('Guardar cápsula'));
    await tester.pumpAndSettle();

    final nueva = capsulas.creadas.single;
    expect(nueva.titulo, 'Para Jacobo');
    expect(nueva.mensaje, 'Ábrela grande');
    expect(nueva.fechaApertura, DateTime(2027, 10, 3, 8));
    expect(nueva.recuerdos.single.tipo, TipoElemento.texto);
    expect(nueva.recuerdos.single.contenidoTexto, 'Te quiero, Jacobo');
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
    await _tocar(tester, find.byKey(const Key('campo-fecha')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Elegir'));
    await tester.pumpAndSettle();
    await _tocar(tester, find.text('Guardar cápsula'));
    await tester.pumpAndSettle();

    expect(
      find.text('Sin conexión. Revisa tu internet e inténtalo de nuevo.'),
      findsOneWidget,
    );
    expect(find.text('Nueva cápsula'), findsOneWidget);
  });

  testWidgets('elige recuerdos guardados sin repetir los ya agregados',
      (tester) async {
    final capsulas = RepositorioCapsulasFalso();
    await montarAppCapsoul(
      tester,
      autenticacion: RepositorioAutenticacionFalso(usuarioInicial: usuarioPrueba),
      capsulas: capsulas,
      recuerdos: RepositorioRecuerdosFalso(iniciales: [
        recuerdoPrueba('a', titulo: 'Playa'),
        recuerdoPrueba('b', titulo: 'Cumpleaños'),
      ]),
    );
    await _abrirNuevaCapsula(tester);

    await _tocar(tester, find.byKey(const Key('boton-elegir-recuerdos')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Playa'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('boton-listo-elegir')));
    await tester.pumpAndSettle();

    expect(find.text('Recuerdos (1/10)'), findsOneWidget);
    expect(find.text('Playa'), findsOneWidget);

    await _tocar(tester, find.byKey(const Key('boton-elegir-recuerdos')));
    await tester.pumpAndSettle();
    expect(find.text('Playa'), findsNothing);
    expect(find.text('Cumpleaños'), findsOneWidget);
  });
}
