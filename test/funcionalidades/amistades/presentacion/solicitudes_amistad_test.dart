import 'package:capsoul/funcionalidades/amistades/dominio/amigo.dart';
import 'package:capsoul/funcionalidades/capsulas/dominio/capsula_recibida.dart';
import 'package:capsoul/funcionalidades/capsulas/dominio/estado_capsula.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../ayudantes/app_prueba.dart';
import '../../../ayudantes/falsos.dart';
import '../../../ayudantes/falsos_amistades.dart';
import '../../../ayudantes/falsos_capsulas.dart';

SolicitudAmistad _solicitud() => SolicitudAmistad(
  id: 'amistad-1',
  solicitanteId: 'solicitante-1',
  solicitanteNombre: 'Ana Privada',
  creadoEn: DateTime.utc(2026, 10, 30),
);

CapsulaRecibida _capsula() => CapsulaRecibida(
  id: 'carta',
  autorId: 'otro',
  autorNombre: 'Beto',
  titulo: 'Carta reciente',
  fechaApertura: DateTime.utc(2026, 10, 2),
  estado: EstadoCapsula.liberada,
  liberadaEn: DateTime.utc(2026, 10, 2),
);

void main() {
  testWidgets(
    'la solicitud aparece en Avisos y en Amigos con Aceptar y Rechazar',
    (tester) async {
      final amistades = RepositorioAmistadesFalso()
        ..solicitudes = [_solicitud()];

      await montarAppCapsoul(
        tester,
        autenticacion: RepositorioAutenticacionFalso(
          usuarioInicial: usuarioPrueba,
        ),
        amistades: amistades,
      );

      expect(find.byKey(const Key('texto-badge-avisos')), findsOneWidget);
      expect(find.text('1'), findsOneWidget);

      await tester.tap(find.byTooltip('Avisos, 1 nuevos'));
      await tester.pumpAndSettle();
      expect(find.text('Ana Privada'), findsOneWidget);
      expect(find.text('Aceptar'), findsOneWidget);
      expect(find.text('Rechazar'), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('boton-rechazar-solicitud-amistad-1')),
      );
      await tester.pumpAndSettle();

      expect(amistades.rechazadas, ['amistad-1']);
      expect(find.text('Ana Privada'), findsNothing);
      expect(
        find.text('Rechazaste la solicitud de Ana Privada.'),
        findsOneWidget,
      );

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('texto-badge-avisos')), findsNothing);
    },
  );

  testWidgets('aceptar baja el contador de Avisos y el de Amigos', (
    tester,
  ) async {
    final amistades = RepositorioAmistadesFalso()..solicitudes = [_solicitud()];
    final capsulas = RepositorioCapsulasFalso()..recibidas.add(_capsula());

    await montarAppCapsoul(
      tester,
      autenticacion: RepositorioAutenticacionFalso(
        usuarioInicial: usuarioPrueba,
      ),
      amistades: amistades,
      capsulas: capsulas,
    );

    expect(find.text('2'), findsOneWidget);

    await tester.tap(find.text('Yo').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('texto-badge-solicitudes')), findsOneWidget);

    await tester.tap(find.text('Amigos e invitaciones'));
    await tester.pumpAndSettle();
    expect(find.text('Aceptar'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const Key('boton-aceptar-solicitud-amistad-1')),
    );
    await tester.tap(
      find.byKey(const Key('boton-aceptar-solicitud-amistad-1')),
    );
    await tester.pumpAndSettle();
    expect(amistades.aceptadas, ['amistad-1']);
    expect(find.text('Quiere ser tu amigo'), findsNothing);

    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('texto-badge-solicitudes')), findsNothing);

    await tester.tap(find.text('Inicio').last);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Avisos, 1 nuevos'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });
}
