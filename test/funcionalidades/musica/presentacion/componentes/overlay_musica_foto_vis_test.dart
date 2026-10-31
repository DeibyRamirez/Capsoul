import 'package:capsoul/funcionalidades/musica/aplicacion/preview_musica_compartido.dart';
import 'package:capsoul/funcionalidades/musica/presentacion/componentes/overlay_musica_foto_vis.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../ayudantes/falsos_musica.dart';

void main() {
  testWidgets(
      'el overlay va directo en el Stack con su margen y sin doble Positioned',
      (tester) async {
    final compartido = PreviewMusicaCompartido();
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: Colors.black),
              OverlayMusicaFotoVis(
                referencia: pistaDeezerPrueba(preview: null),
                previewMusica: compartido,
                margenLateral: 16,
                margenInferior: 24,
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    final posicion = tester.widget<Positioned>(
      find.descendant(
        of: find.byType(OverlayMusicaFotoVis),
        matching: find.byType(Positioned),
      ),
    );
    expect(posicion.left, 16);
    expect(posicion.right, 16);
    expect(posicion.bottom, 24);
    expect(
      find.ancestor(
        of: find.byType(OverlayMusicaFotoVis),
        matching: find.byType(Positioned),
      ),
      findsNothing,
    );
  });
}
