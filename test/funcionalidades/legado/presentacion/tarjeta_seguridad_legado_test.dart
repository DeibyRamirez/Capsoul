import 'package:capsoul/funcionalidades/legado/presentacion/componentes/tarjeta_seguridad_legado.dart';
import 'package:capsoul/nucleo/componentes/tarjeta_capsoul.dart';
import 'package:capsoul/nucleo/tema/tema_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('la tarjeta de seguridad usa el diseño Capsoul', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: TemaApp.claro,
        home: const Scaffold(body: TarjetaSeguridadLegado()),
      ),
    );

    expect(find.byType(TarjetaCapsoul), findsOneWidget);
    expect(find.text('Tu espacio seguro'), findsOneWidget);
    expect(find.text('Ver seguridad y respaldo'), findsOneWidget);
    expect(find.byIcon(Icons.verified_user_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
