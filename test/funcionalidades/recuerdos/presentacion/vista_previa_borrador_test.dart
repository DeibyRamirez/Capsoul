import 'package:capsoul/funcionalidades/elementos/dominio/elemento_borrador.dart';
import 'package:capsoul/funcionalidades/elementos/dominio/tipo_elemento.dart';
import 'package:capsoul/funcionalidades/musica/dominio/referencia_musica.dart';
import 'package:capsoul/funcionalidades/musica/presentacion/componentes/reproductor_preview_musica.dart';
import 'package:capsoul/funcionalidades/recuerdos/presentacion/componentes/vista_previa_borrador.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

bool _tieneVolteoHorizontal(Widget widget) {
  if (widget is! Transform) return false;
  return widget.transform.entry(0, 0) < 0;
}

void main() {
  testWidgets(
    'foto con esCamaraFrontal no aplica Transform de espejo horizontal',
    (tester) async {
      final elemento = ElementoBorrador(
        idLocal: 'f1',
        tipo: TipoElemento.foto,
        rutaArchivo: 'ruta_inexistente_capsoul_test.jpg',
        bytes: 100,
        esCamaraFrontal: true,
        formato: 'jpg',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: VistaPreviaBorrador(elemento: elemento),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(VistaPreviaBorrador), findsOneWidget);
      expect(
        find.byWidgetPredicate(_tieneVolteoHorizontal),
        findsNothing,
      );
    },
  );

  testWidgets('foto con música muestra un solo reproductor y botón quitar', (
    tester,
  ) async {
    const musica = ReferenciaMusica(
      idExterno: 't1',
      titulo: 'Tú No Lo Amas',
      artista: 'Anuel AA',
      urlCompleta: 'https://open.spotify.com/track/t1',
      previewUrl: 'https://preview.example/track.mp3',
    );
    final elemento = ElementoBorrador(
      idLocal: 'f1',
      tipo: TipoElemento.foto,
      rutaArchivo: 'ruta_inexistente_capsoul_test.jpg',
      bytes: 100,
      referenciaMusica: musica,
      formato: 'jpg',
    );
    var quitado = false;

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: VistaPreviaBorrador(
              elemento: elemento,
              alQuitarMusica: () => quitado = true,
            ),
          ),
        ),
      )),
    );
    await tester.pump();

    expect(find.byType(ReproductorPreviewMusica), findsOneWidget);
    expect(find.text('Anuel AA — Tú No Lo Amas'), findsOneWidget);
    final quitar = find.byIcon(Icons.close);
    await tester.ensureVisible(quitar);
    await tester.tap(quitar);
    expect(quitado, isTrue);
  });
}
