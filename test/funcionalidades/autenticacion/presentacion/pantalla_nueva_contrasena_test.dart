import 'package:capsoul/funcionalidades/autenticacion/presentacion/pantalla_nueva_contrasena.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../ayudantes/app_prueba.dart';
import '../../../ayudantes/falsos.dart';

void main() {
  Finder campo(String etiqueta) =>
      find.widgetWithText(TextFormField, etiqueta);

  Future<RepositorioAutenticacionFalso> abrirEnlaceRecuperacion(
    WidgetTester tester,
  ) async {
    final autenticacion = RepositorioAutenticacionFalso();
    await montarAppCapsoul(tester, autenticacion: autenticacion);
    autenticacion.simularEnlaceRecuperacion();
    await tester.pumpAndSettle();
    return autenticacion;
  }

  testWidgets('el enlace de recuperación abre la pantalla de nueva contraseña',
      (tester) async {
    await abrirEnlaceRecuperacion(tester);

    expect(find.text('Escribe tu nueva contraseña.'), findsOneWidget);
    expect(find.text('Guardar algo hoy'), findsNothing);
  });

  testWidgets('valida que las contraseñas coincidan', (tester) async {
    final autenticacion = await abrirEnlaceRecuperacion(tester);

    await tester.enterText(campo('Nueva contraseña'), 'nueva-secreta1');
    await tester.enterText(campo('Confirmar contraseña'), 'otra-cosa12');
    await tester.tap(find.text('Guardar contraseña'));
    await tester.pumpAndSettle();

    expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
    expect(autenticacion.ultimaContrasenaNueva, isNull);
  });

  testWidgets('guardar actualiza la contraseña y entra al contenedor',
      (tester) async {
    final autenticacion = await abrirEnlaceRecuperacion(tester);

    await tester.enterText(campo('Nueva contraseña'), 'nueva-secreta1');
    await tester.enterText(campo('Confirmar contraseña'), 'nueva-secreta1');
    await tester.tap(find.text('Guardar contraseña'));
    await tester.pumpAndSettle();

    expect(autenticacion.ultimaContrasenaNueva, 'nueva-secreta1');
    expect(find.text(kMensajeContrasenaActualizada), findsOneWidget);
    expect(find.text('Guardar algo hoy'), findsOneWidget);
  });

  testWidgets('cancelar cierra la sesión temporal', (tester) async {
    final autenticacion = await abrirEnlaceRecuperacion(tester);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(autenticacion.llamadasCerrarSesion, 1);
    expect(find.widgetWithText(FilledButton, 'Iniciar sesión'), findsOneWidget);
  });
}
