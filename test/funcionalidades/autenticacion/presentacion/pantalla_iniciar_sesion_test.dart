import 'dart:async';

import 'package:capsoul/funcionalidades/autenticacion/dominio/fallo_autenticacion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../ayudantes/app_prueba.dart';
import '../../../ayudantes/falsos.dart';

void main() {
  Finder campo(String etiqueta) =>
      find.widgetWithText(TextFormField, etiqueta);
  Finder botonIniciarSesion() => find.byType(FilledButton);

  testWidgets('campos vacíos muestran errores en español', (tester) async {
    await montarAppCapsoul(
      tester,
      autenticacion: RepositorioAutenticacionFalso(),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
    await tester.pumpAndSettle();

    expect(find.text('Ingresa tu correo electrónico'), findsOneWidget);
    expect(find.text('Ingresa tu contraseña'), findsOneWidget);
  });

  testWidgets('correo inválido muestra error', (tester) async {
    await montarAppCapsoul(
      tester,
      autenticacion: RepositorioAutenticacionFalso(),
    );

    await tester.enterText(campo('Correo electrónico'), 'ana');
    await tester.enterText(campo('Contraseña'), 'secreta123');
    await tester.tap(botonIniciarSesion());
    await tester.pumpAndSettle();

    expect(find.text('Ingresa un correo electrónico válido'), findsOneWidget);
  });

  testWidgets('botón deshabilitado mientras carga y luego entra al contenedor',
      (tester) async {
    final autenticacion = RepositorioAutenticacionFalso()
      ..compuertaInicioSesion = Completer<void>();
    await montarAppCapsoul(tester, autenticacion: autenticacion);

    await tester.enterText(campo('Correo electrónico'), 'ana@capsoul.app');
    await tester.enterText(campo('Contraseña'), 'secreta123');
    await tester.tap(botonIniciarSesion());
    await tester.pump();

    expect(tester.widget<FilledButton>(botonIniciarSesion()).onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    autenticacion.compuertaInicioSesion!.complete();
    await tester.pumpAndSettle();

    expect(find.text('Hola'), findsOneWidget);
  });

  testWidgets('credenciales inválidas muestran SnackBar en español',
      (tester) async {
    final autenticacion = RepositorioAutenticacionFalso()
      ..siguienteFallo = FalloAutenticacion.desdeCodigo('invalid-credential');
    await montarAppCapsoul(tester, autenticacion: autenticacion);

    await tester.enterText(campo('Correo electrónico'), 'ana@capsoul.app');
    await tester.enterText(campo('Contraseña'), 'mala');
    await tester.tap(botonIniciarSesion());
    await tester.pumpAndSettle();

    expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(botonIniciarSesion()).onPressed,
      isNotNull,
    );
  });

  testWidgets('mostrar/ocultar contraseña', (tester) async {
    await montarAppCapsoul(
      tester,
      autenticacion: RepositorioAutenticacionFalso(),
    );

    EditableText textoContrasena() => tester.widget<EditableText>(
          find.descendant(
            of: campo('Contraseña'),
            matching: find.byType(EditableText),
          ),
        );

    expect(textoContrasena().obscureText, isTrue);
    await tester.tap(find.byTooltip('Mostrar contraseña'));
    await tester.pump();
    expect(textoContrasena().obscureText, isFalse);
  });
}
