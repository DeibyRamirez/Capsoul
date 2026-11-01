import 'package:capsoul/funcionalidades/musica/aplicacion/proveedores_musica.dart';
import 'package:capsoul/funcionalidades/musica/dominio/fallo_musica.dart';
import 'package:capsoul/funcionalidades/musica/dominio/referencia_musica.dart';
import 'package:capsoul/funcionalidades/musica/presentacion/componentes/credito_deezer.dart';
import 'package:capsoul/funcionalidades/musica/presentacion/pantalla_buscar_musica.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../ayudantes/falsos_musica.dart';

const _espera = Duration(milliseconds: 20);

Future<void> _montar(
  WidgetTester tester,
  CatalogoMusicaFalso catalogo, {
  void Function(ReferenciaMusica?)? alVolver,
  bool soloSeleccion = false,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        proveedorRepositorioCatalogoMusica.overrideWithValue(catalogo),
        proveedorEsperaBusquedaMusica.overrideWithValue(_espera),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  final pista = await Navigator.of(context).push(
                    MaterialPageRoute<ReferenciaMusica>(
                      builder: (_) =>
                          PantallaBuscarMusica(soloSeleccion: soloSeleccion),
                    ),
                  );
                  alVolver?.call(pista);
                },
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

Future<void> _escribir(WidgetTester tester, String texto) async {
  await tester.enterText(find.byKey(const Key('campo_buscar_musica')), texto);
  await tester.pump(_espera * 2);
  await tester.pump();
}

void main() {
  testWidgets('muestra el estado inicial y el crédito de Deezer', (
    tester,
  ) async {
    await _montar(tester, CatalogoMusicaFalso());
    expect(find.text('Buscar música'), findsOneWidget);
    expect(find.text('Busca por artista o canción.'), findsOneWidget);
    expect(
      find.text('Escribe el nombre de una canción o de un artista.'),
      findsOneWidget,
    );
    expect(find.byType(CreditoDeezer), findsOneWidget);
    expect(find.text('Música de Deezer'), findsOneWidget);
  });

  testWidgets('busca con debounce y lista los resultados', (tester) async {
    final catalogo = CatalogoMusicaFalso(
      respuestas: {
        'daft punk': [
          pistaDeezerPrueba(),
          pistaDeezerPrueba(id: '2', titulo: 'Sin clip', preview: ''),
        ],
      },
    );
    await _montar(tester, catalogo);

    await _escribir(tester, 'daft punk');

    expect(catalogo.consultas, ['daft punk']);
    expect(find.text('Harder, Better, Faster, Stronger'), findsOneWidget);
    expect(find.text('Vista previa de 30 s'), findsOneWidget);
    expect(find.byTooltip('Escuchar vista previa'), findsNWidgets(2));
  });

  testWidgets('sin resultados muestra el estado vacío', (tester) async {
    await _montar(tester, CatalogoMusicaFalso());
    await _escribir(tester, 'zzzz');
    expect(find.text('No encontramos canciones para «zzzz».'), findsOneWidget);
  });

  testWidgets('error muestra mensaje y Reintentar vuelve a buscar', (
    tester,
  ) async {
    final catalogo = CatalogoMusicaFalso(
      respuestas: {
        'daft': [pistaDeezerPrueba()],
      },
    )..fallo = const FalloMusica(TipoFalloMusica.sinConexion);
    await _montar(tester, catalogo);

    await _escribir(tester, 'daft');
    expect(find.textContaining('Sin conexión'), findsOneWidget);

    catalogo.fallo = null;
    await tester.tap(find.text('Reintentar'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Harder, Better, Faster, Stronger'), findsOneWidget);
    expect(catalogo.consultas, ['daft', 'daft']);
  });

  testWidgets('tocar una canción la devuelve', (tester) async {
    ReferenciaMusica? devuelta;
    final catalogo = CatalogoMusicaFalso(
      respuestas: {
        'daft': [pistaDeezerPrueba()],
      },
    );
    await _montar(tester, catalogo, alVolver: (p) => devuelta = p);

    await _escribir(tester, 'daft');
    await tester.tap(find.text('Harder, Better, Faster, Stronger'));
    await tester.pumpAndSettle();

    expect(devuelta?.idExterno, '3135556');
    expect(find.byType(PantallaBuscarMusica), findsNothing);
  });

  testWidgets('en solo selección confirma con Usar esta canción', (
    tester,
  ) async {
    ReferenciaMusica? devuelta;
    final catalogo = CatalogoMusicaFalso(
      respuestas: {
        'daft': [pistaDeezerPrueba()],
      },
    );
    await _montar(
      tester,
      catalogo,
      soloSeleccion: true,
      alVolver: (p) => devuelta = p,
    );

    expect(find.text('Elegir música'), findsOneWidget);
    await _escribir(tester, 'daft');
    await tester.tap(find.text('Harder, Better, Faster, Stronger'));
    await tester.pump();
    expect(find.byType(PantallaBuscarMusica), findsOneWidget);

    await tester.tap(find.text('Usar esta canción'));
    await tester.pumpAndSettle();

    expect(devuelta?.idExterno, '3135556');
    expect(find.byType(PantallaBuscarMusica), findsNothing);
  });
}
