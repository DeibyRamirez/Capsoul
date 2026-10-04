import 'package:capsoul/funcionalidades/inicio/dominio/resumen_inicio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../ayudantes/app_prueba.dart';
import '../../../ayudantes/falsos.dart';
import '../../../ayudantes/falsos_capsulas.dart';

void main() {
  testWidgets('Inicio muestra el mockup con los conteos reales', (tester) async {
    await montarAppCapsoul(
      tester,
      autenticacion: RepositorioAutenticacionFalso(usuarioInicial: usuarioPrueba),
      resumen: RepositorioResumenInicioFalso(
        const ResumenInicio(recuerdos: 128, retosActivos: 3, capsulas: 1, herencias: 2),
      ),
    );

    expect(find.text('cápsoul'), findsOneWidget);
    expect(find.text('Pequeñas herencias, grandes recuerdos'), findsOneWidget);
    expect(find.text('Tu vida.'), findsOneWidget);
    expect(find.text('Guardar algo hoy'), findsOneWidget);
    expect(find.text('¿Qué quieres dejar para el futuro?'), findsOneWidget);
    expect(find.byTooltip('Avisos'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Pequeñas herencias'), 200);
    expect(find.text('128'), findsOneWidget);
    expect(find.text('recuerdos guardados'), findsOneWidget);
    expect(find.text('retos activos'), findsOneWidget);
    expect(find.text('cápsula creada'), findsOneWidget);
    expect(find.text('herencias creadas'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('No se trata de tener más tiempo, sino de dejar lo que importa.'),
      200,
    );
  });

  testWidgets('sin datos los conteos valen 0', (tester) async {
    await montarAppCapsoul(
      tester,
      autenticacion: RepositorioAutenticacionFalso(usuarioInicial: usuarioPrueba),
    );
    await tester.scrollUntilVisible(find.text('Pequeñas herencias'), 200);
    expect(find.text('0'), findsNWidgets(4));
  });

  testWidgets('la tarjeta Cápsulas abre Mis cápsulas', (tester) async {
    await montarAppCapsoul(
      tester,
      autenticacion: RepositorioAutenticacionFalso(usuarioInicial: usuarioPrueba),
    );
    // Se baja hasta el banner para que la tarjeta no quede bajo la barra.
    await tester.scrollUntilVisible(find.textContaining('No se trata de tener'), 200);
    await tester.tap(find.text('Guarda hoy, abre en el futuro.'));
    await tester.pumpAndSettle();

    expect(find.text('Mis cápsulas'), findsOneWidget);
    expect(find.textContaining('Aún no tienes cápsulas'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
