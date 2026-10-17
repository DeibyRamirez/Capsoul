import 'package:capsoul/funcionalidades/capsulas/dominio/capsula.dart';
import 'package:capsoul/funcionalidades/capsulas/dominio/estado_capsula.dart';
import 'package:capsoul/funcionalidades/capsulas/presentacion/componentes/tarjeta_capsula_lista.dart';
import 'package:capsoul/nucleo/tema/tema_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra título, Abrir en y candado si fecha futura', (tester) async {
    final capsula = Capsula(
      id: 'c1',
      autorId: 'u1',
      titulo: 'Para Juan',
      mensaje: '20 años de amor',
      estado: EstadoCapsula.programada,
      creadoEn: DateTime(2026, 1, 1),
      fechaApertura: DateTime(2046, 9, 14),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: TemaApp.claro,
        home: Scaffold(
          body: TarjetaCapsulaLista.propia(
            capsula: capsula,
            ahora: DateTime(2026, 10, 1),
            uidActual: 'u1',
          ),
        ),
      ),
    );

    expect(find.text('Para Juan'), findsOneWidget);
    expect(find.text('20 años de amor'), findsOneWidget);
    expect(find.text('Abrir en'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
  });
}
