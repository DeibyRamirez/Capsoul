import 'package:capsoul/funcionalidades/amistades/aplicacion/proveedores_amistades.dart';
import 'package:capsoul/funcionalidades/autenticacion/aplicacion/proveedores_autenticacion.dart';
import 'package:capsoul/funcionalidades/legado/aplicacion/proveedores_legado.dart';
import 'package:capsoul/funcionalidades/legado/presentacion/pantalla_legado.dart';
import 'package:capsoul/nucleo/tema/tema_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../ayudantes/falsos.dart';
import '../../../ayudantes/falsos_amistades.dart';
import '../../../ayudantes/falsos_legado.dart';

void main() {
  testWidgets('Mi legado muestra Creadas y Recibidas', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          proveedorRepositorioLegado.overrideWithValue(RepositorioLegadoFalso()),
          proveedorRepositorioAmistades.overrideWithValue(
            RepositorioAmistadesFalso(),
          ),
          proveedorEstadoAutenticacion.overrideWith(
            (ref) => Stream.value(usuarioPrueba),
          ),
        ],
        child: MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 1200),
            disableAnimations: true,
          ),
          child: MaterialApp(
            theme: TemaApp.claro,
            home: const PantallaLegado(),
          ),
        ),
      ),
    );
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
}
