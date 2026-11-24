import 'package:capsoul/funcionalidades/legado/aplicacion/proveedores_legado.dart';
import 'package:capsoul/funcionalidades/legado/dominio/acceso_herencia.dart';
import 'package:capsoul/funcionalidades/legado/dominio/condicion_herencia.dart';
import 'package:capsoul/funcionalidades/legado/dominio/estado_herencia.dart';
import 'package:capsoul/funcionalidades/legado/dominio/herencia.dart';
import 'package:capsoul/funcionalidades/legado/presentacion/pantalla_desbloquear_herencia.dart';
import 'package:capsoul/nucleo/tema/tema_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../ayudantes/falsos_legado.dart';

Widget _app(RepositorioLegadoFalso repo) {
  final router = GoRouter(
    initialLocation: '/legado/herencia/h1/desbloquear',
    routes: [
      GoRoute(
        path: '/legado/herencia/:id/desbloquear',
        builder: (_, _) =>
            const PantallaDesbloquearHerencia(herenciaId: 'h1'),
      ),
      GoRoute(
        path: '/legado/herencia/:id',
        builder: (_, _) => const Text('detalle-herencia'),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      proveedorRepositorioLegado.overrideWithValue(repo),
    ],
    child: MaterialApp.router(
      theme: TemaApp.claro,
      routerConfig: router,
    ),
  );
}

Herencia _herencia({required EstadoHerencia estado}) {
  return Herencia(
    id: 'h1',
    titulo: 'Reloj de familia',
    estado: estado,
    condicionActivacion: CondicionHerencia.fecha,
    fechaActivacion: DateTime(2046, 8, 13),
    propietarioId: 'u1',
    beneficiarioUsuarioId: 'u2',
    personaConfianzaId: 'u3',
  );
}

void main() {
  testWidgets('una herencia sellada no pide código todavía', (tester) async {
    final repo = RepositorioLegadoFalso()
      ..detalle = DetalleHerencia(
        herencia: _herencia(estado: EstadoHerencia.activa),
        esConfianza: true,
      );
    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();

    expect(find.text('Todavía no se puede abrir'), findsOneWidget);
    expect(find.byKey(const ValueKey('campo_codigo_herencia')), findsNothing);
  });

  testWidgets('al liberar la herencia pide el código y desbloquea', (
    tester,
  ) async {
    final repo = RepositorioLegadoFalso()
      ..detalle = DetalleHerencia(
        herencia: _herencia(estado: EstadoHerencia.liberada),
        esConfianza: true,
      )
      ..estadoAcceso = const EstadoAccesoHerencia(
        esConfianza: true,
        liberada: true,
        intentosRestantes: 5,
      );
    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();

    expect(find.text('Ingresa el código'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('campo_codigo_herencia')),
      '123456',
    );
    await tester.tap(find.text('Desbloquear'));
    await tester.pumpAndSettle();

    expect(find.text('detalle-herencia'), findsOneWidget);
  });

  testWidgets('reenviar el código llama al repositorio', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repo = RepositorioLegadoFalso()
      ..detalle = DetalleHerencia(
        herencia: _herencia(estado: EstadoHerencia.liberada),
        esConfianza: true,
      )
      ..estadoAcceso = const EstadoAccesoHerencia(
        esConfianza: true,
        liberada: true,
      );
    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Reenviar código'));
    await tester.tap(find.text('Reenviar código'));
    await tester.pumpAndSettle();

    expect(repo.codigosSolicitados, 1);
  });
}
