import 'package:capsoul/funcionalidades/capsulas/aplicacion/proveedores_capsulas.dart';
import 'package:capsoul/funcionalidades/capsulas/dominio/capsula.dart';
import 'package:capsoul/funcionalidades/capsulas/dominio/capsula_recibida.dart';
import 'package:capsoul/funcionalidades/capsulas/dominio/estado_capsula.dart';
import 'package:capsoul/funcionalidades/capsulas/presentacion/pantalla_mis_capsulas.dart';
import 'package:capsoul/funcionalidades/capsulas/presentacion/vista_capsulas_tab.dart';
import 'package:capsoul/nucleo/tema/tema_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final capsulaPropia = Capsula(
    id: 'm1',
    autorId: 'yo',
    titulo: 'Mi cápsula propia',
    estado: EstadoCapsula.programada,
    creadoEn: DateTime(2026, 1, 1),
    fechaApertura: DateTime(2030, 1, 1),
  );

  final recibida = CapsulaRecibida(
    id: 'r1',
    autorId: 'otro',
    autorNombre: 'Ana',
    titulo: 'Sorpresa',
    fechaApertura: DateTime(2030, 1, 1),
    estado: EstadoCapsula.programada,
  );

  testWidgets('pestaña Mis cápsulas muestra solo propias', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          proveedorMisCapsulas.overrideWith((ref) async => [capsulaPropia]),
          proveedorCapsulasRecibidas.overrideWith((ref) async => [recibida]),
          proveedorReloj.overrideWithValue(() => DateTime(2026, 6, 1)),
        ],
        child: MaterialApp(
          theme: TemaApp.claro,
          home: const PantallaMisCapsulas(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mi cápsula propia'), findsOneWidget);
    expect(find.text('Sorpresa'), findsNothing);
  });

  testWidgets('pestaña Para mí muestra recibidas', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          proveedorMisCapsulas.overrideWith((ref) async => [capsulaPropia]),
          proveedorCapsulasRecibidas.overrideWith((ref) async => [recibida]),
          proveedorReloj.overrideWithValue(() => DateTime(2026, 6, 1)),
        ],
        child: MaterialApp(
          theme: TemaApp.claro,
          home: const PantallaMisCapsulas(
            vistaInicial: VistaCapsulasTab.paraMi,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cápsula para ti'), findsOneWidget);
    expect(find.text('Mi cápsula propia'), findsNothing);
  });
}
