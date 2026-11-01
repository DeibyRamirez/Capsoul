import 'package:capsoul/funcionalidades/legado/presentacion/pantalla_seguridad_legado.dart';
import 'package:capsoul/nucleo/componentes/tarjeta_capsoul.dart';
import 'package:capsoul/nucleo/tema/tema_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('seguridad muestra cabecera y cuatro tarjetas', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: TemaApp.claro, home: const PantallaSeguridadLegado()),
    );

    expect(find.text('Seguridad y respaldo'), findsOneWidget);
    expect(find.text('Cómo protegemos tu legado'), findsOneWidget);
    expect(find.text('Medios autenticados'), findsOneWidget);
    expect(find.text('Solo tú editas'), findsOneWidget);
    expect(find.text('Persona de confianza'), findsOneWidget);
    expect(find.text('Respaldo jurídico'), findsOneWidget);
    expect(find.byType(TarjetaCapsoul), findsNWidgets(4));
  });
}
