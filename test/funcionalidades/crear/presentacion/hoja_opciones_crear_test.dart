import 'package:capsoul/funcionalidades/elementos/dominio/nota_serializada.dart';
import 'package:flutter/material.dart';
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
      autenticacion: RepositorioAutenticacionFalso(usuarioInicial: usuarioPrueba),
      recuerdos: recuerdos,
    );

    await tester.tap(find.text('Guardar algo hoy'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Texto'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('campo-nota')), 'Desde la hoja');
    await tester.tap(find.text('Guardar nota'));
    await tester.pumpAndSettle();

    expect(find.text('Guardar recuerdo'), findsWidgets);

    await tester.tap(find.widgetWithText(FilledButton, 'Guardar recuerdo'));
    await tester.pumpAndSettle();

    final creado = recuerdos.creados.single;
    expect(
      NotaSerializada.parse(creado.elemento.texto).cuerpo,
      'Desde la hoja',
    );
  });
}
