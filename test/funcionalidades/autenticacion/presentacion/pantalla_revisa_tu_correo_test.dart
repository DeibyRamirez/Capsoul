import 'dart:async';

import 'package:capsoul/funcionalidades/autenticacion/aplicacion/proveedores_autenticacion.dart';
import 'package:capsoul/funcionalidades/autenticacion/dominio/fallo_autenticacion.dart';
import 'package:capsoul/funcionalidades/autenticacion/presentacion/pantalla_revisa_tu_correo.dart';
import 'package:capsoul/nucleo/enrutador/rutas_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../ayudantes/falsos.dart';

void main() {
  const correo = 'ana@capsoul.app';

  Future<void> montarPantalla(
    WidgetTester tester,
    RepositorioAutenticacionFalso autenticacion, {
    bool reenviar = false,
  }) async {
    final enrutador = GoRouter(
      initialLocation: RutasApp.revisaTuCorreoPara(correo, reenviar: reenviar),
      routes: [
        GoRoute(
          path: RutasApp.revisaTuCorreo,
          builder: (context, state) => PantallaRevisaTuCorreo(
            correo: state.uri.queryParameters['correo'] ?? '',
            reenviarAlEntrar: state.uri.queryParameters['reenviar'] == '1',
          ),
        ),
        GoRoute(
          path: RutasApp.iniciarSesion,
          builder: (context, state) =>
              const Scaffold(body: Text('Pantalla de inicio de sesión')),
        ),
      ],
    );
    addTearDown(enrutador.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          proveedorRepositorioAutenticacion.overrideWithValue(autenticacion),
        ],
        child: MaterialApp.router(routerConfig: enrutador),
      ),
    );
    await tester.pump();
  }

  Finder botonReenviar() => find.byType(FilledButton);
  bool reenvioHabilitado(WidgetTester tester) =>
      tester.widget<FilledButton>(botonReenviar()).onPressed != null;

  testWidgets('muestra el correo y espera el enfriamiento antes de reenviar',
      (tester) async {
    final autenticacion = RepositorioAutenticacionFalso();
    await montarPantalla(tester, autenticacion);

    expect(find.text('Revisa tu correo'), findsOneWidget);
    expect(find.text(correo), findsOneWidget);
    expect(find.text('Reenviar en 60 s'), findsOneWidget);
    expect(reenvioHabilitado(tester), isFalse);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Reenviar en 59 s'), findsOneWidget);

    await tester.pump(kEnfriamientoReenvio);
    expect(find.text('Reenviar correo'), findsOneWidget);
    expect(reenvioHabilitado(tester), isTrue);
    expect(autenticacion.correosConfirmacionReenviados, isEmpty);
  });

  testWidgets(
      'reenviar muestra carga, confirma el envío y reinicia el enfriamiento',
      (tester) async {
    final autenticacion = RepositorioAutenticacionFalso();
    await montarPantalla(tester, autenticacion);
    await tester.pump(kEnfriamientoReenvio);

    autenticacion.compuertaReenvio = Completer<void>();
    await tester.tap(botonReenviar());
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      tester
          .widget<OutlinedButton>(find.byType(OutlinedButton))
          .onPressed,
      isNull,
    );

    autenticacion.compuertaReenvio!.complete();
    await tester.pump();
    await tester.pump();

    expect(autenticacion.correosConfirmacionReenviados, [correo]);
    expect(find.text(kMensajeCorreoReenviado), findsOneWidget);
    expect(find.text('Reenviar en 60 s'), findsOneWidget);
    expect(reenvioHabilitado(tester), isFalse);
  });

  testWidgets('un error del reenvío se muestra en español y permite reintentar',
      (tester) async {
    final autenticacion = RepositorioAutenticacionFalso();
    await montarPantalla(tester, autenticacion);
    await tester.pump(kEnfriamientoReenvio);

    autenticacion.siguienteFallo =
        FalloAutenticacion.desdeCodigo('over_email_send_rate_limit');
    await tester.tap(botonReenviar());
    await tester.pump();
    await tester.pump();

    expect(
      find.text(
        'Demasiados intentos. Espera unos minutos e inténtalo de nuevo.',
      ),
      findsOneWidget,
    );
    expect(find.text(kMensajeCorreoReenviado), findsNothing);
    expect(reenvioHabilitado(tester), isTrue);
  });

  testWidgets('desde el inicio de sesión reenvía al entrar', (tester) async {
    final autenticacion = RepositorioAutenticacionFalso();
    await montarPantalla(tester, autenticacion, reenviar: true);
    await tester.pump();

    expect(autenticacion.correosConfirmacionReenviados, [correo]);
    expect(find.text(kMensajeCorreoReenviado), findsOneWidget);
    expect(find.text('Reenviar en 60 s'), findsOneWidget);
  });

  testWidgets('Volver a iniciar sesión navega al inicio de sesión',
      (tester) async {
    await montarPantalla(tester, RepositorioAutenticacionFalso());

    await tester.tap(find.text('Volver a iniciar sesión'));
    await tester.pumpAndSettle();

    expect(find.text('Pantalla de inicio de sesión'), findsOneWidget);
  });
}
