import 'package:capsoul/funcionalidades/amistades/aplicacion/proveedores_amistades.dart';
import 'package:capsoul/funcionalidades/autenticacion/aplicacion/proveedores_autenticacion.dart';
import 'package:capsoul/funcionalidades/legado/aplicacion/proveedores_legado.dart';
import 'package:capsoul/funcionalidades/legado/dominio/herencia_recibida.dart';
import 'package:capsoul/funcionalidades/legado/presentacion/pantalla_legado.dart';
import 'package:capsoul/nucleo/tema/tema_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../ayudantes/falsos.dart';
import '../../../ayudantes/falsos_amistades.dart';
import '../../../ayudantes/falsos_legado.dart';

Widget _appLegado({
  required RepositorioLegadoFalso repo,
  Size viewport = const Size(360, 1200),
}) {
  return ProviderScope(
    overrides: [
      proveedorRepositorioLegado.overrideWithValue(repo),
      proveedorRepositorioAmistades.overrideWithValue(
        RepositorioAmistadesFalso(),
      ),
      proveedorEstadoAutenticacion.overrideWith(
        (ref) => Stream.value(usuarioPrueba),
      ),
    ],
    child: MediaQuery(
      data: MediaQueryData(size: viewport, disableAnimations: true),
      child: MaterialApp(
        theme: TemaApp.claro,
        home: const PantallaLegado(),
      ),
    ),
  );
}

void main() {
  testWidgets('Mi legado muestra Creadas y Recibidas', (tester) async {
    await tester.pumpWidget(_appLegado(repo: RepositorioLegadoFalso()));
    await tester.pumpAndSettle();
    expect(find.text('Creadas'), findsOneWidget);
    expect(find.text('Recibidas'), findsOneWidget);
    expect(find.text('Para las personas que amo'), findsOneWidget);

    await tester.tap(find.text('Recibidas'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Cuando alguien te asigne una pequeña herencia, aparecerá aquí.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'confirmar legado cabe en 360dp sin romper el layout',
    (tester) async {
      final repo = RepositorioLegadoFalso()
        ..porConfirmar.add(
          const HerenciaPorConfirmar(
            id: 'h-conf',
            titulo: 'Reloj de familia para un legado largo',
            propietarioId: 'u1',
            propietarioNombre: 'Ana Pérez de los Andes',
            beneficiarioNombre: 'Carlos Gómez Martínez',
          ),
        );
      await tester.pumpWidget(
        _appLegado(repo: repo, viewport: const Size(360, 800)),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Te piden confirmar un legado'), findsOneWidget);
      expect(find.text('Confirmar'), findsOneWidget);
      expect(find.byType(ListTile), findsNothing);
    },
  );
}
