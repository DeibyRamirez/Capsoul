import 'package:capsoul/funcionalidades/retos/aplicacion/proveedores_retos.dart';
import 'package:capsoul/funcionalidades/retos/dominio/reto.dart';
import 'package:capsoul/funcionalidades/retos/presentacion/pantalla_retos.dart';
import 'package:capsoul/nucleo/tema/tema_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Reto _reto(
  int orden, {
  bool completado = false,
  String? titulo,
}) =>
    Reto(
      id: 'id_$orden',
      slug: 'slug_$orden',
      titulo: titulo ?? 'Reto $orden',
      descripcion: 'Descripción $orden',
      pasos: const ['Paso uno'],
      orden: orden,
      criterioClave: 'test',
      completado: completado,
    );

void main() {
  testWidgets('pestaña Activos muestra secciones del mockup', (tester) async {
    final lista = [_reto(1), _reto(2), _reto(3), _reto(4, titulo: 'Especial')];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          proveedorListaRetos.overrideWith((ref) async => lista),
        ],
        child: MaterialApp(
          theme: TemaApp.claro,
          home: const PantallaRetos(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Reto diario'), findsOneWidget);
    expect(find.text('Retos semanales'), findsOneWidget);
    expect(find.text('Retos especiales'), findsOneWidget);
    expect(find.text('Reto 1'), findsOneWidget);
  });

  testWidgets('pestaña Completados filtra retos terminados', (tester) async {
    final lista = [
      _reto(1, completado: true, titulo: 'Hecho'),
      _reto(2, titulo: 'Pendiente'),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          proveedorListaRetos.overrideWith((ref) async => lista),
        ],
        child: MaterialApp(
          theme: TemaApp.claro,
          home: const PantallaRetos(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Completados'));
    await tester.pumpAndSettle();

    expect(find.text('Hecho'), findsOneWidget);
    expect(find.text('Pendiente'), findsNothing);
  });

  testWidgets('pestaña Favoritos muestra mensaje vacío', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          proveedorListaRetos.overrideWith((ref) async => [_reto(1)]),
        ],
        child: MaterialApp(
          theme: TemaApp.claro,
          home: const PantallaRetos(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Favoritos'));
    await tester.pumpAndSettle();

    expect(
      find.text('Próximamente podrás marcar retos favoritos.'),
      findsOneWidget,
    );
  });
}
