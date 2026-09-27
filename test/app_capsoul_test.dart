import 'package:flutter_test/flutter_test.dart';

import 'ayudantes/app_prueba.dart';
import 'ayudantes/falsos.dart';

void main() {
  testWidgets('AppCapsoul muestra el contenedor de Inicio con sesión',
      (tester) async {
    await montarAppCapsoul(
      tester,
      autenticacion: RepositorioAutenticacionFalso(usuarioInicial: usuarioPrueba),
    );

    expect(find.text('Hola'), findsOneWidget);
    expect(find.text('Bienvenido a Capsoul'), findsOneWidget);
    expect(find.text('Inicio'), findsWidgets);
    expect(find.text('Momentos'), findsWidgets);
    expect(find.text('Mi legado'), findsWidgets);
    expect(find.text('Yo'), findsWidgets);
  });

  testWidgets('sin sesión redirige a /iniciar-sesion y oculta el contenedor',
      (tester) async {
    await montarAppCapsoul(
      tester,
      autenticacion: RepositorioAutenticacionFalso(),
    );

    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Pequeñas herencias, grandes recuerdos'), findsOneWidget);
    expect(find.text('Inicio'), findsNothing);
    expect(find.text('Hola'), findsNothing);
  });

  testWidgets('el botón + abre el selector de Crear', (tester) async {
    await montarAppCapsoul(
      tester,
      autenticacion: RepositorioAutenticacionFalso(usuarioInicial: usuarioPrueba),
    );

    await tester.tap(find.text('+'));
    await tester.pumpAndSettle();

    expect(find.text('Crear'), findsOneWidget);
    expect(find.text('Graba un recuerdo en video'), findsOneWidget);
  });
}
