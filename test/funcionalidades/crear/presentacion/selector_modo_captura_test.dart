import 'package:capsoul/funcionalidades/crear/dominio/modo_captura.dart';
import 'package:capsoul/funcionalidades/crear/presentacion/componentes/selector_modo_captura.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SelectorModoCaptura anuncia modos y cambia selección', (
    tester,
  ) async {
    var seleccionado = ModoCaptura.video;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SelectorModoCaptura(
            modos: const [ModoCaptura.video, ModoCaptura.foto, ModoCaptura.texto],
            seleccionado: seleccionado,
            alCambiar: (m) => seleccionado = m,
          ),
        ),
      ),
    );

    expect(find.text('Foto'), findsOneWidget);
    await tester.tap(find.text('Foto'));
    await tester.pumpAndSettle();
    expect(seleccionado, ModoCaptura.foto);
  });
}
