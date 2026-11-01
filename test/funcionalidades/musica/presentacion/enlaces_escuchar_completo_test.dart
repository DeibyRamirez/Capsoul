import 'package:capsoul/funcionalidades/musica/aplicacion/abridor_enlaces_musica.dart';
import 'package:capsoul/funcionalidades/musica/aplicacion/proveedores_musica.dart';
import 'package:capsoul/funcionalidades/musica/presentacion/componentes/enlaces_escuchar_completo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../ayudantes/falsos_musica.dart';

void main() {
  testWidgets('los botones abren Deezer, Spotify y YouTube', (tester) async {
    final abiertos = <Uri>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          proveedorAbridorEnlacesMusica.overrideWithValue(
            AbridorEnlacesMusica(
              puedeAbrir: (_) async => true,
              abrir: (uri) async {
                abiertos.add(uri);
                return true;
              },
            ),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: EnlacesEscucharCompleto(referencia: pistaDeezerPrueba(id: '8')),
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Abrir en Deezer'));
    await tester.pump();
    await tester.tap(find.byTooltip('Buscar en Spotify'));
    await tester.pump();
    await tester.tap(find.byTooltip('Buscar en YouTube'));
    await tester.pump();

    expect(abiertos.map((u) => u.scheme == 'deezer' ? u.toString() : u.host), [
      'deezer://www.deezer.com/track/8',
      'open.spotify.com',
      'www.youtube.com',
    ]);
  });

  testWidgets('avisa si no se pudo abrir', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          proveedorAbridorEnlacesMusica.overrideWithValue(
            AbridorEnlacesMusica(
              puedeAbrir: (_) async => false,
              abrir: (_) async => false,
            ),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: EnlacesEscucharCompleto(referencia: pistaDeezerPrueba()),
          ),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Buscar en YouTube'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('No se pudo abrir YouTube.'), findsOneWidget);
  });
}
