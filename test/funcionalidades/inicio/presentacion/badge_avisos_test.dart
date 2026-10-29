import 'package:capsoul/funcionalidades/capsulas/dominio/capsula.dart';
import 'package:capsoul/funcionalidades/capsulas/dominio/capsula_recibida.dart';
import 'package:capsoul/funcionalidades/capsulas/dominio/estado_capsula.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../ayudantes/app_prueba.dart';
import '../../../ayudantes/falsos.dart';
import '../../../ayudantes/falsos_capsulas.dart';

const _claveBadge = Key('texto-badge-avisos');

CapsulaRecibida _aviso({
  required String id,
  required String titulo,
  required DateTime liberadaEn,
  DateTime? leidaEn,
  String autorId = 'otro',
  EstadoCapsula estado = EstadoCapsula.liberada,
}) {
  return CapsulaRecibida(
    id: id,
    autorId: autorId,
    autorNombre: 'Beto',
    titulo: titulo,
    fechaApertura: liberadaEn,
    estado: estado,
    liberadaEn: estado == EstadoCapsula.liberada ? liberadaEn : null,
    leidaEn: leidaEn,
  );
}

void main() {
  testWidgets('sin avisos nuevos el badge no se muestra', (tester) async {
    final capsulas = RepositorioCapsulasFalso();
    capsulas.recibidas.addAll([
      _aviso(
        id: 'propia',
        titulo: 'La mía',
        autorId: usuarioPrueba.uid,
        liberadaEn: DateTime.utc(2026, 10, 2),
      ),
      _aviso(
        id: 'leida',
        titulo: 'Ya la vi',
        liberadaEn: DateTime.utc(2026, 10, 1),
        leidaEn: DateTime.utc(2026, 10, 2),
      ),
      _aviso(
        id: 'cerrada',
        titulo: 'Aún no',
        liberadaEn: DateTime.utc(2026, 11, 1),
        estado: EstadoCapsula.programada,
      ),
    ]);

    await montarAppCapsoul(
      tester,
      autenticacion: RepositorioAutenticacionFalso(
        usuarioInicial: usuarioPrueba,
      ),
      capsulas: capsulas,
    );

    expect(find.byTooltip('Avisos'), findsOneWidget);
    expect(find.byKey(_claveBadge), findsNothing);
  });

  testWidgets('el badge muestra el conteo cuando hay avisos nuevos', (
    tester,
  ) async {
    final capsulas = RepositorioCapsulasFalso();
    for (var i = 0; i < 3; i++) {
      capsulas.recibidas.add(
        _aviso(
          id: 'n$i',
          titulo: 'Aviso $i',
          liberadaEn: DateTime.utc(2026, 10, i + 1),
        ),
      );
    }

    await montarAppCapsoul(
      tester,
      autenticacion: RepositorioAutenticacionFalso(
        usuarioInicial: usuarioPrueba,
      ),
      capsulas: capsulas,
    );

    expect(find.byKey(_claveBadge), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('con más de 9 avisos el badge dice 9+', (tester) async {
    final capsulas = RepositorioCapsulasFalso();
    for (var i = 0; i < 10; i++) {
      capsulas.recibidas.add(
        _aviso(
          id: 'n$i',
          titulo: 'Aviso $i',
          liberadaEn: DateTime.utc(2026, 9, i + 1),
        ),
      );
    }

    await montarAppCapsoul(
      tester,
      autenticacion: RepositorioAutenticacionFalso(
        usuarioInicial: usuarioPrueba,
      ),
      capsulas: capsulas,
    );

    expect(find.text('9+'), findsOneWidget);
    expect(find.byKey(_claveBadge), findsOneWidget);
  });

  testWidgets('ver un aviso lo marca como leído y el contador baja', (
    tester,
  ) async {
    final capsulas = RepositorioCapsulasFalso();
    capsulas.recibidas.addAll([
      _aviso(
        id: 'antigua',
        titulo: 'Carta antigua',
        liberadaEn: DateTime.utc(2026, 9, 1),
      ),
      _aviso(
        id: 'reciente',
        titulo: 'Carta reciente',
        liberadaEn: DateTime.utc(2026, 10, 2),
      ),
    ]);
    capsulas.capsulas['reciente'] = Capsula(
      id: 'reciente',
      autorId: 'otro',
      titulo: 'Carta reciente',
      estado: EstadoCapsula.liberada,
      creadoEn: DateTime.utc(2026, 9, 1),
      fechaApertura: DateTime.utc(2026, 10, 2),
      liberadaEn: DateTime.utc(2026, 10, 2),
    );

    await montarAppCapsoul(
      tester,
      autenticacion: RepositorioAutenticacionFalso(
        usuarioInicial: usuarioPrueba,
      ),
      capsulas: capsulas,
    );
    expect(find.text('2'), findsOneWidget);

    await tester.tap(find.byTooltip('Avisos, 2 nuevos'));
    await tester.pumpAndSettle();

    expect(find.text('Avisos'), findsOneWidget);
    final reciente = tester.getTopLeft(find.text('Carta reciente'));
    final antigua = tester.getTopLeft(find.text('Carta antigua'));
    expect(reciente.dy, lessThan(antigua.dy));

    await tester.tap(find.text('Carta reciente'));
    await tester.pumpAndSettle();

    expect(capsulas.avisosMarcados, ['reciente']);
    expect(find.text('Abrir cápsula'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byTooltip('Avisos, 1 nuevos'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });
}
