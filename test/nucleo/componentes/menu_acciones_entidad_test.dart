import 'package:capsoul/nucleo/componentes/menu_acciones_entidad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('expande y confirma eliminar', (tester) async {
    var eliminado = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topRight,
            child: MenuAccionesEntidad(
              puedeEliminar: true,
              alEliminar: () => eliminado = true,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('menu-acciones-ancla')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();
    expect(eliminado, isFalse);

    await tester.tap(find.widgetWithText(TextButton, 'Eliminar'));
    await tester.pumpAndSettle();
    expect(eliminado, isTrue);
  });

  testWidgets('menú compacto confirma eliminar', (tester) async {
    var eliminado = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            actions: [
              MenuAccionesEntidad(
                compacto: true,
                puedeEliminar: true,
                alEliminar: () => eliminado = true,
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('menu-acciones-ancla')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Eliminar'));
    await tester.pumpAndSettle();
    expect(eliminado, isTrue);
  });

  testWidgets('no elimina si cancela', (tester) async {
    var eliminado = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MenuAccionesEntidad(
            puedeEliminar: true,
            alEliminar: () => eliminado = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('menu-acciones-ancla')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(eliminado, isFalse);
  });
}
