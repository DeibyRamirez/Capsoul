import 'package:capsoul/funcionalidades/capsulas/dominio/capsula.dart';
import 'package:capsoul/funcionalidades/capsulas/dominio/capsula_recibida.dart';
import 'package:capsoul/funcionalidades/capsulas/dominio/estado_capsula.dart';
import 'package:capsoul/funcionalidades/capsulas/presentacion/componentes/tarjeta_capsula_lista.dart';
import 'package:capsoul/nucleo/tema/tema_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final ahora = DateTime(2026, 10, 1, 12);

  Capsula propia({
    required EstadoCapsula estado,
    DateTime? fecha,
    DateTime? abiertaEn,
    DateTime? liberadaEn,
  }) =>
      Capsula(
        id: 'c1',
        autorId: 'u1',
        titulo: 'Para Juan',
        mensaje: '20 años de amor',
        estado: estado,
        creadoEn: DateTime(2026, 1, 1),
        fechaApertura: fecha,
        liberadaEn: liberadaEn,
        abiertaEn: abiertaEn,
      );

  Future<void> montar(WidgetTester tester, Widget tarjeta) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: TemaApp.claro,
        home: Scaffold(body: tarjeta),
      ),
    );
  }

  testWidgets('programada futura muestra fecha y hora, no lista para abrir',
      (tester) async {
    await montar(
      tester,
      TarjetaCapsulaLista.propia(
        capsula: propia(
          estado: EstadoCapsula.programada,
          fecha: DateTime(2046, 9, 14, 8, 5),
        ),
        ahora: ahora,
      ),
    );

    expect(find.text('Para Juan'), findsOneWidget);
    expect(find.text('20 años de amor'), findsOneWidget);
    expect(find.text('Programada'), findsOneWidget);
    expect(find.text('14 sep 2046 · 08:05'), findsOneWidget);
    expect(find.text('Lista para abrir'), findsNothing);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
  });

  testWidgets('programada vencida sigue sellada hasta que el cron la libere',
      (tester) async {
    await montar(
      tester,
      TarjetaCapsulaLista.propia(
        capsula: propia(
          estado: EstadoCapsula.programada,
          fecha: ahora.subtract(const Duration(hours: 2)),
        ),
        ahora: ahora,
      ),
    );

    expect(find.text('Programada'), findsOneWidget);
    expect(find.text('Aún no liberada'), findsOneWidget);
    expect(find.text('Lista para abrir'), findsNothing);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
  });

  testWidgets('borrador, lista, abierta y cancelada se leen en la tarjeta',
      (tester) async {
    Future<void> espera(EstadoCapsula estado, String etiqueta, {DateTime? abierta}) async {
      await montar(
        tester,
        TarjetaCapsulaLista.propia(
          capsula: propia(
            estado: estado,
            fecha: DateTime(2026, 9, 1, 9),
            abiertaEn: abierta,
            liberadaEn: estado == EstadoCapsula.liberada ? DateTime(2026, 9, 1) : null,
          ),
          ahora: ahora,
        ),
      );
      expect(find.text(etiqueta), findsOneWidget);
    }

    await espera(EstadoCapsula.borrador, 'Borrador');
    expect(find.text('Sin fecha'), findsNothing);
    expect(find.text('1 sep 2026 · 09:00'), findsOneWidget);

    await montar(
      tester,
      TarjetaCapsulaLista.propia(
        capsula: propia(estado: EstadoCapsula.borrador),
        ahora: ahora,
      ),
    );
    expect(find.text('Borrador'), findsOneWidget);
    expect(find.text('Sin fecha'), findsOneWidget);

    await espera(EstadoCapsula.liberada, 'Lista para abrir');
    expect(find.byIcon(Icons.lock_outline), findsNothing);

    await espera(
      EstadoCapsula.liberada,
      'Abierta',
      abierta: DateTime(2026, 9, 2),
    );
    await espera(EstadoCapsula.cancelada, 'Cancelada');
  });

  testWidgets('recibida liberada y abierta usa el estado real', (tester) async {
    await montar(
      tester,
      TarjetaCapsulaLista.recibida(
        recibida: CapsulaRecibida(
          id: 'r1',
          autorId: 'otro',
          autorNombre: 'Ana',
          titulo: 'Sorpresa',
          fechaApertura: ahora.subtract(const Duration(days: 1)),
          estado: EstadoCapsula.liberada,
          abiertaEn: ahora,
        ),
        ahora: ahora,
      ),
    );
    expect(find.text('Abierta'), findsOneWidget);
    expect(find.text('Lista para abrir'), findsNothing);
    expect(find.text('Sorpresa'), findsOneWidget);
  });
}
