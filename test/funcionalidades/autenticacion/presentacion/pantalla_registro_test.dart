import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../ayudantes/app_prueba.dart';
import '../../../ayudantes/falsos.dart';

void main() {
  Finder campo(String etiqueta) =>
      find.widgetWithText(TextFormField, etiqueta);
  Finder botonCrearCuenta() => find.widgetWithText(FilledButton, 'Crear cuenta');

  Future<void> abrirRegistro(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(TextButton, 'Crear cuenta'));
    await tester.pumpAndSettle();
  }

  testWidgets('valida campos vacíos, longitud y coincidencia', (tester) async {
    await montarAppCapsoul(
      tester,
      autenticacion: RepositorioAutenticacionFalso(),
    );
    await abrirRegistro(tester);

    await tester.tap(botonCrearCuenta());
    await tester.pumpAndSettle();
    expect(find.text('Ingresa tu nombre'), findsOneWidget);
    expect(find.text('Ingresa tu correo electrónico'), findsOneWidget);
    expect(find.text('Ingresa una contraseña'), findsOneWidget);
    expect(find.text('Confirma tu contraseña'), findsOneWidget);

    await tester.enterText(campo('Contraseña'), '1234567');
    await tester.enterText(campo('Confirmar contraseña'), '7654321');
    await tester.tap(botonCrearCuenta());
    await tester.pumpAndSettle();
    expect(
      find.text('La contraseña debe tener al menos 8 caracteres'),
      findsOneWidget,
    );
    expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
  });

  Future<void> llenarFormulario(WidgetTester tester) async {
    await tester.enterText(campo('Nombre'), ' Ana María ');
    await tester.enterText(campo('Correo electrónico'), 'ana@capsoul.app');
    await tester.enterText(campo('Contraseña'), 'secreta123');
    await tester.enterText(campo('Confirmar contraseña'), 'secreta123');
    await tester.tap(botonCrearCuenta());
    await tester.pumpAndSettle();
  }

  testWidgets('con sesión al registrarse entra al inicio', (tester) async {
    final autenticacion = RepositorioAutenticacionFalso();
    await montarAppCapsoul(tester, autenticacion: autenticacion);
    await abrirRegistro(tester);

    await llenarFormulario(tester);

    expect(autenticacion.ultimoNombreRegistrado, 'Ana María');
    expect(find.text('Hola'), findsOneWidget);
  });

  testWidgets(
      'si falta confirmar el correo muestra Revisa tu correo con el correo',
      (tester) async {
    final autenticacion =
        RepositorioAutenticacionFalso(exigeConfirmarCorreo: true);
    await montarAppCapsoul(tester, autenticacion: autenticacion);
    await abrirRegistro(tester);

    await llenarFormulario(tester);

    expect(find.text('Revisa tu correo'), findsOneWidget);
    expect(find.text('ana@capsoul.app'), findsOneWidget);
    expect(find.text('Volver a iniciar sesión'), findsOneWidget);
    expect(find.text('Hola'), findsNothing);
    expect(autenticacion.usuarioActual, isNull);
  });
}
