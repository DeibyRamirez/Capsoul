import 'package:capsoul/funcionalidades/amistades/aplicacion/proveedores_amistades.dart';
import 'package:capsoul/funcionalidades/autenticacion/aplicacion/proveedores_autenticacion.dart';
import 'package:capsoul/funcionalidades/legado/aplicacion/proveedores_legado.dart';
import 'package:capsoul/funcionalidades/legado/dominio/condicion_herencia.dart';
import 'package:capsoul/funcionalidades/legado/dominio/estado_herencia.dart';
import 'package:capsoul/funcionalidades/legado/dominio/herencia_recibida.dart';
import 'package:capsoul/funcionalidades/legado/presentacion/componentes/tarjeta_herencia_recibida.dart';
import 'package:capsoul/funcionalidades/legado/presentacion/pantalla_legado.dart';
import 'package:capsoul/nucleo/tema/tema_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../ayudantes/falsos.dart';
import '../../../ayudantes/falsos_amistades.dart';
import '../../../ayudantes/falsos_legado.dart';

Widget _appLegado({
  required RepositorioLegadoFalso repo,
  Size viewport = const Size(360, 1200),
}) {
  return ProviderScope(
    overrides: [
      proveedorRepositorioLegado.overrideWithValue(repo),
      proveedorRepositorioAmistades.overrideWithValue(
        RepositorioAmistadesFalso(),
      ),
      proveedorEstadoAutenticacion.overrideWith(
        (ref) => Stream.value(usuarioPrueba),
      ),
    ],
    child: MediaQuery(
      data: MediaQueryData(size: viewport, disableAnimations: true),
      child: MaterialApp(theme: TemaApp.claro, home: const PantallaLegado()),
    ),
  );
}

void main() {
  testWidgets('Mi legado muestra Creadas y Recibidas', (tester) async {
    await tester.pumpWidget(_appLegado(repo: RepositorioLegadoFalso()));
    await tester.pumpAndSettle();
    expect(find.text('Creadas'), findsOneWidget);
    expect(find.text('Recibidas'), findsOneWidget);
    expect(find.text('Para las personas que amo'), findsOneWidget);

    await tester.tap(find.text('Recibidas'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Todavía no hay herencias'), 200);
    expect(find.text('Todavía no hay herencias'), findsOneWidget);
    expect(
      find.text(
        'Cuando alguien te confíe parte de su historia, la encontrarás aquí.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('la herencia recibida usa la tarjeta temática de Capsoul', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repo = RepositorioLegadoFalso()
      ..recibidas.add(
        HerenciaRecibida(
          id: 'h-recibida',
          titulo: 'Reloj de mi abuelo',
          estado: EstadoHerencia.activa,
          condicionActivacion: CondicionHerencia.fecha,
          fechaActivacion: DateTime(2046, 8, 13),
          propietarioId: 'u1',
          propietarioNombre: 'Ana Pérez',
          contenidoVisible: false,
          nCapsulas: 2,
        ),
      );
    await tester.pumpWidget(_appLegado(repo: repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Recibidas'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byType(TarjetaHerenciaRecibida), 200);

    expect(find.byType(TarjetaHerenciaRecibida), findsOneWidget);
    expect(find.text('Reloj de mi abuelo'), findsOneWidget);
    expect(find.text('Ana Pérez te lo confió'), findsOneWidget);
    expect(find.text('Sellada'), findsOneWidget);
    expect(find.text('2 cápsulas'), findsOneWidget);
    expect(find.text('Se abre el 13 ago 2046'), findsOneWidget);
  });

  testWidgets('confirmar legado cabe en 360dp sin romper el layout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repo = RepositorioLegadoFalso()
      ..porConfirmar.add(
        const HerenciaPorConfirmar(
          id: 'h-conf',
          titulo: 'Reloj de familia para un legado largo',
          propietarioId: 'u1',
          propietarioNombre: 'Ana Pérez de los Andes',
          beneficiarioNombre: 'Carlos Gómez Martínez',
        ),
      );
    await tester.pumpWidget(
      _appLegado(repo: repo, viewport: const Size(360, 800)),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Una llave en tus manos'), findsOneWidget);
    expect(find.text('Confirmar entrega'), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
  });
}
