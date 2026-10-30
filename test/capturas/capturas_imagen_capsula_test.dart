import 'package:capsoul/funcionalidades/capsulas/dominio/capsula.dart';
import 'package:capsoul/funcionalidades/capsulas/dominio/estado_capsula.dart';
import 'package:capsoul/funcionalidades/capsulas/dominio/imagen_capsula.dart';
import 'package:capsoul/funcionalidades/capsulas/presentacion/componentes/selector_imagen_capsula.dart';
import 'package:capsoul/funcionalidades/capsulas/presentacion/componentes/tarjeta_capsula_lista.dart';
import 'package:capsoul/nucleo/tema/tema_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Capturas de referencia (golden). Regenerar con:
/// flutter test --update-goldens test/capturas
void main() {
  Future<void> precargar(WidgetTester tester) async {
    await tester.runAsync(() async {
      for (final element in find.byType(Image).evaluate()) {
        final imagen = element.widget as Image;
        await precacheImage(imagen.image, element);
      }
    });
    await tester.pumpAndSettle();
  }

  testWidgets('tarjetas de Mis capsulas con imagen', (tester) async {
    tester.view.physicalSize = const Size(400, 520);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    Capsula capsula(String id, String? clave, EstadoCapsula estado) => Capsula(
          id: id,
          autorId: 'u1',
          titulo: 'Capsula $id',
          mensaje: 'Para abrir en el futuro',
          estado: estado,
          creadoEn: DateTime(2026, 1, 1),
          fechaApertura: DateTime(2030, 1, 1),
          liberadaEn: estado == EstadoCapsula.liberada ? DateTime(2026) : null,
          imagenClave: clave,
        );
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: TemaApp.claro,
        home: Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              for (final c in [
                capsula('1', 'capsula_05', EstadoCapsula.programada),
                capsula('2', 'capsula_13', EstadoCapsula.liberada),
                capsula('3', null, EstadoCapsula.programada),
              ]) ...[
                TarjetaCapsulaLista.propia(
                  capsula: c,
                  ahora: DateTime(2026, 10, 30),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
    await precargar(tester);
    expect(find.byKey(const ValueKey('imagen-capsula-capsula_05')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('imagen-capsula-capsula_01')),
        findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/tarjetas_mis_capsulas.png'),
    );
  });

  testWidgets('selector de imagen en crear capsula', (tester) async {
    tester.view.physicalSize = const Size(400, 560);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    String? elegida = 'capsula_07';
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: TemaApp.claro,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(12),
            child: StatefulBuilder(
              builder: (context, setState) => SelectorImagenCapsula(
                seleccionada: elegida,
                alElegir: (c) => setState(() => elegida = c),
              ),
            ),
          ),
        ),
      ),
    );
    await precargar(tester);
    expect(find.byType(InkWell), findsNWidgets(ImagenCapsula.values.length));
    await tester.tap(find.byKey(const Key('opcion-imagen-capsula_02')));
    await tester.pumpAndSettle();
    expect(elegida, 'capsula_02');
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/selector_imagen_capsula.png'),
    );
  });
}