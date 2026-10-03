import 'dart:async';

import 'package:capsoul/funcionalidades/elementos/aplicacion/controlador_grabacion_audio.dart';
import 'package:capsoul/funcionalidades/elementos/aplicacion/proveedores_elementos.dart';
import 'package:capsoul/funcionalidades/elementos/dominio/compresor_medios.dart';
import 'package:capsoul/funcionalidades/elementos/dominio/elemento_borrador.dart';
import 'package:capsoul/funcionalidades/elementos/dominio/grabadora_audio.dart';
import 'package:capsoul/funcionalidades/elementos/dominio/tipo_elemento.dart';
import 'package:capsoul/funcionalidades/elementos/dominio/validador_medios.dart';
import 'package:capsoul/funcionalidades/elementos/presentacion/pantalla_grabar_audio.dart';
import 'package:capsoul/nucleo/tema/tema_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _GrabadoraFalsa implements GrabadoraAudio {
  bool permiso = true;
  bool grabando = false;
  bool cancelada = false;
  final flujoNiveles = StreamController<double>.broadcast();

  @override
  Future<bool> tienePermiso() async => permiso;

  @override
  Future<void> iniciar() async => grabando = true;

  @override
  Future<String?> detener() async {
    grabando = false;
    return '/tmp/audio.m4a';
  }

  @override
  Future<void> cancelar() async {
    grabando = false;
    cancelada = true;
  }

  @override
  Stream<double> niveles() => flujoNiveles.stream;

  @override
  Future<void> liberar() async {}
}

class _CompresorFalso implements CompresorMedios {
  Duration? duracionRecibida;

  @override
  Future<ElementoBorrador> prepararAudio(
    String ruta,
    Duration duracion,
    List<double> muestrasOnda,
  ) async {
    duracionRecibida = duracion;
    final fallo = ValidadorMedios.validarMedio(
      tipo: TipoElemento.audio,
      bytes: 1000,
      duracion: duracion,
    );
    if (fallo != null) throw fallo;
    return ElementoBorrador(
      idLocal: 'a1',
      tipo: TipoElemento.audio,
      rutaArchivo: ruta,
      bytes: 1000,
      duracion: duracion,
      muestrasOnda: muestrasOnda,
    );
  }

  @override
  Future<ElementoBorrador> prepararFoto(String rutaOriginal) =>
      throw UnimplementedError();

  @override
  Future<ElementoBorrador> prepararVideo(String ruta, Duration duracion) =>
      throw UnimplementedError();
}

Future<void> _montar(
  WidgetTester tester,
  _GrabadoraFalsa grabadora,
  _CompresorFalso compresor,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        proveedorFabricaGrabadora.overrideWithValue(() => grabadora),
        proveedorCompresorMedios.overrideWithValue(compresor),
      ],
      child: MaterialApp(theme: TemaApp.claro, home: const PantallaGrabarAudio()),
    ),
  );
}

void main() {
  testWidgets('graba con contador y onda y termina al tocar detener',
      (tester) async {
    final grabadora = _GrabadoraFalsa();
    final compresor = _CompresorFalso();
    await _montar(tester, grabadora, compresor);

    expect(find.text('00:00 / 05:00'), findsOneWidget);
    await tester.tap(find.byTooltip('Empezar a grabar'));
    await tester.pump();
    expect(grabadora.grabando, isTrue);

    grabadora.flujoNiveles.add(0.8);
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('00:03 / 05:00'), findsOneWidget);
    expect(find.text('Grabando… toca para terminar.'), findsOneWidget);

    await tester.tap(find.byTooltip('Detener grabación'));
    await tester.pumpAndSettle();

    expect(compresor.duracionRecibida, const Duration(seconds: 3));
    expect(find.text('Usar nota de voz'), findsOneWidget);
  });

  testWidgets('se detiene sola a los 5 minutos', (tester) async {
    final grabadora = _GrabadoraFalsa();
    final compresor = _CompresorFalso();
    await _montar(tester, grabadora, compresor);

    await tester.tap(find.byTooltip('Empezar a grabar'));
    await tester.pump();
    await tester.pump(const Duration(minutes: 5));
    await tester.pumpAndSettle();

    expect(grabadora.grabando, isFalse);
    expect(compresor.duracionRecibida, const Duration(minutes: 5));
    expect(find.text('Usar nota de voz'), findsOneWidget);
  });

  testWidgets('sin permiso del micrófono avisa en español', (tester) async {
    final grabadora = _GrabadoraFalsa()..permiso = false;
    await _montar(tester, grabadora, _CompresorFalso());

    await tester.tap(find.byTooltip('Empezar a grabar'));
    await tester.pump();

    expect(find.textContaining('permiso para usar el micrófono'), findsOneWidget);
    expect(grabadora.grabando, isFalse);
  });

  test('reducirMuestras promedia tramos', () {
    expect(reducirMuestras([0, 1, 0, 1], 2), [0.5, 0.5]);
    expect(reducirMuestras([0.2], 4), [0.2]);
    expect(reducirMuestras(const [], 4), isEmpty);
  });
}
