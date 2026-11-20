import 'package:capsoul/funcionalidades/elementos/dominio/nota_serializada.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_test/flutter_test.dart';

import '../../../ayudantes/app_prueba.dart';
import '../../../ayudantes/falsos.dart';
import '../../../ayudantes/falsos_recuerdos.dart';

void main() {
  testWidgets('desde el hub Texto abre escribir y guardar recuerdo', (
    tester,
  ) async {
    final recuerdos = RepositorioRecuerdosFalso();
    await montarAppCapsoul(
      tester,
      autenticacion: RepositorioAutenticacionFalso(
        usuarioInicial: usuarioPrueba,
      ),
      recuerdos: recuerdos,
    );

    await tester.tap(find.text('Guardar algo hoy'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Texto'));
    await tester.pumpAndSettle();

    final editor = tester.widget<quill.QuillEditor>(
      find.byKey(const Key('campo-nota')),
    );
    editor.controller.replaceText(
      0,
      0,
      'Desde la hoja',
      const TextSelection.collapsed(offset: 13),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('guardar-nota')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('campo-titulo-rapido')), findsOneWidget);

    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    final creado = recuerdos.creados.single;
    expect(
      NotaSerializada.parse(creado.elemento.texto).cuerpo,
      'Desde la hoja',
    );
  });
}
