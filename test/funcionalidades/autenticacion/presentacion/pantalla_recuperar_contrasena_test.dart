import 'package:capsoul/funcionalidades/autenticacion/dominio/fallo_autenticacion.dart';
import 'package:capsoul/funcionalidades/autenticacion/presentacion/pantalla_recuperar_contrasena.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../ayudantes/app_prueba.dart';
import '../../../ayudantes/falsos.dart';

void main() {
  Finder campoCorreo() =>
      find.widgetWithText(TextFormField, 'Correo electrónico');
  Finder botonEnviar() => find.widgetWithText(FilledButton, 'Enviar enlace');

  Future<void> abrirRecuperacion(WidgetTester tester) async {
    await tester.tap(find.text('¿Olvidaste tu contraseña?'));
    await tester.pumpAndSettle();
  }

  testWidgets('correo vacío muestra error', (tester) async {
    await montarAppCapsoul(
      tester,
      autenticacion: RepositorioAutenticacionFalso(),
    );
    await abrirRecuperacion(tester);

    await tester.tap(botonEnviar());
    await tester.pumpAndSettle();

    expect(find.text('Ingresa tu correo electrónico'), findsOneWidget);
  });

  testWidgets('user-not-found muestra la misma confirmación neutra y vuelve',
      (tester) async {
    final autenticacion = RepositorioAutenticacionFalso()
      ..siguienteFallo = FalloAutenticacion.desdeCodigo('user-not-found');
    await montarAppCapsoul(tester, autenticacion: autenticacion);
    await abrirRecuperacion(tester);

    await tester.enterText(campoCorreo(), 'nadie@capsoul.app');
    await tester.tap(botonEnviar());
    await tester.pumpAndSettle();

    expect(find.text(kMensajeEnlaceRecuperacionEnviado), findsOneWidget);
    expect(find.text('Correo o contraseña incorrectos.'), findsNothing);

    await tester.tap(find.text('Volver a iniciar sesión'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilledButton, 'Iniciar sesión'), findsOneWidget);
  });

  testWidgets('envía el enlace al correo indicado', (tester) async {
    final autenticacion = RepositorioAutenticacionFalso();
    await montarAppCapsoul(tester, autenticacion: autenticacion);
    await abrirRecuperacion(tester);

    await tester.enterText(campoCorreo(), ' ana@capsoul.app ');
    await tester.tap(botonEnviar());
    await tester.pumpAndSettle();

    expect(autenticacion.ultimoCorreoRecuperacion, 'ana@capsoul.app');
    expect(find.text(kMensajeEnlaceRecuperacionEnviado), findsOneWidget);
  });
}
