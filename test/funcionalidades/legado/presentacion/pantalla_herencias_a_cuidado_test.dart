import 'package:capsoul/funcionalidades/legado/aplicacion/proveedores_legado.dart';
import 'package:capsoul/funcionalidades/legado/dominio/acceso_herencia.dart';
import 'package:capsoul/funcionalidades/legado/dominio/condicion_herencia.dart';
import 'package:capsoul/funcionalidades/legado/dominio/estado_herencia.dart';
import 'package:capsoul/funcionalidades/legado/presentacion/pantalla_herencias_a_cuidado.dart';
import 'package:capsoul/nucleo/tema/tema_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../ayudantes/falsos_legado.dart';

void main() {
  testWidgets('muestra los legados donde soy persona de confianza', (
    tester,
  ) async {
    final repo = RepositorioLegadoFalso()
      ..aCuidado.add(
        HerenciaACuidado(
          id: 'h1',
          titulo: 'Reloj de familia',
          estado: EstadoHerencia.activa,
          condicionActivacion: CondicionHerencia.fecha,
          fechaActivacion: DateTime(2046, 8, 13),
          propietarioId: 'u1',
          propietarioNombre: 'Ana Pérez',
          contenidoVisible: false,
          accesoActivo: false,
          nCapsulas: 2,
        ),
      );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          proveedorRepositorioLegado.overrideWithValue(repo),
        ],
        child: MaterialApp(
          theme: TemaApp.claro,
          home: const PantallaHerenciasACuidado(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Legados a mi cuidado'), findsOneWidget);
    expect(find.text('Reloj de familia'), findsOneWidget);
    expect(
      find.text('Ana Pérez te eligió como persona de confianza.'),
      findsOneWidget,
    );
    expect(find.text('Sellada'), findsOneWidget);
    expect(find.text('2 cápsulas'), findsOneWidget);
  });

  testWidgets('sin legados muestra el estado vacío', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          proveedorRepositorioLegado.overrideWithValue(
            RepositorioLegadoFalso(),
          ),
        ],
        child: MaterialApp(
          theme: TemaApp.claro,
          home: const PantallaHerenciasACuidado(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Todavía no custodias ningún legado'), findsOneWidget);
  });
}
