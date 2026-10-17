import 'package:capsoul/funcionalidades/retos/dominio/reto.dart';
import 'package:capsoul/funcionalidades/retos/presentacion/componentes/item_reto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ItemReto muestra título y check cuando está completado', (tester) async {
    const reto = Reto(
      id: 'r1',
      slug: 'recuerdo_nota',
      titulo: 'Escribe una nota',
      descripcion: 'Deja tus palabras.',
      pasos: ['Toca +'],
      orden: 1,
      criterioClave: 'recuerdo_nota',
      completado: true,
    );
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: ItemReto(reto: reto))),
    );
    expect(find.text('Escribe una nota'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });
}
