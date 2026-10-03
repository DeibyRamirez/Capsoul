import 'package:capsoul/funcionalidades/autenticacion/aplicacion/proveedores_autenticacion.dart';
import 'package:capsoul/funcionalidades/autenticacion/dominio/usuario_app.dart';
import 'package:capsoul/funcionalidades/capsulas/aplicacion/proveedores_capsulas.dart';
import 'package:capsoul/funcionalidades/capsulas/dominio/capsula.dart';
import 'package:capsoul/funcionalidades/capsulas/dominio/estado_capsula.dart';
import 'package:capsoul/funcionalidades/capsulas/presentacion/pantalla_detalle_capsula.dart';
import 'package:capsoul/funcionalidades/elementos/dominio/tipo_elemento.dart';
import 'package:capsoul/funcionalidades/recuerdos/aplicacion/proveedores_recuerdos.dart';
import 'package:capsoul/funcionalidades/recuerdos/dominio/recuerdo.dart';
import 'package:capsoul/nucleo/tema/tema_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../ayudantes/falsos.dart';
import '../../../ayudantes/falsos_capsulas.dart';
import '../../../ayudantes/falsos_recuerdos.dart';

final _ahora = DateTime(2026, 10, 3, 10);

Capsula _capsula({DateTime? fechaApertura}) => Capsula(
      id: 'c1',
      autorId: 'uid-123',
      titulo: 'Para Jacobo',
      mensaje: 'Quiero que sepas que eres lo mejor que me ha pasado.',
      estado: EstadoCapsula.programada,
      creadoEn: DateTime(2026, 8, 13),
      fechaApertura: fechaApertura ?? DateTime(2046, 8, 13, 8),
      elementos: [
        Recuerdo(
          id: 'e1',
          propietarioId: 'uid-123',
          tipo: TipoElemento.video,
          fechaRecuerdo: DateTime(2026, 8, 13),
          creadoEn: DateTime(2026, 8, 13),
          duracion: const Duration(minutes: 5, seconds: 30),
        ),
        Recuerdo(
          id: 'e2',
          propietarioId: 'uid-123',
          tipo: TipoElemento.audio,
          fechaRecuerdo: DateTime(2026, 8, 13),
          creadoEn: DateTime(2026, 8, 13),
          duracion: const Duration(minutes: 1, seconds: 32),
        ),
      ],
    );

Future<void> _montar(
  WidgetTester tester, {
  required Capsula capsula,
  String uid = 'uid-123',
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final repositorio = RepositorioCapsulasFalso()..capsulas['c1'] = capsula;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        proveedorRepositorioAutenticacion.overrideWithValue(
          RepositorioAutenticacionFalso(
            usuarioInicial: UsuarioApp(uid: uid, correoVerificado: true),
          ),
        ),
        proveedorRepositorioCapsulas.overrideWithValue(repositorio),
        proveedorRepositorioUrlsMedio.overrideWithValue(
          RepositorioUrlsMedioFalso(),
        ),
        proveedorArchivosMedio.overrideWithValue(ArchivosMedioFalso()),
        proveedorReloj.overrideWithValue(() => _ahora),
      ],
      child: MaterialApp(
        theme: TemaApp.claro,
        home: const PantallaDetalleCapsula(idCapsula: 'c1'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('sellada: el autor ve candado, cuenta regresiva y su contenido',
      (tester) async {
    await _montar(tester, capsula: _capsula());

    expect(find.text('Para Jacobo'), findsOneWidget);
    expect(find.text('Mensaje para dentro de 20 años'), findsOneWidget);
    expect(find.text('Abrir en'), findsOneWidget);
    expect(find.text('13 ago 2046'), findsOneWidget);
    expect(find.text('Faltan 19 años, 10 meses y 9 días'), findsOneWidget);
    expect(find.text('Sobre esta cápsula'), findsOneWidget);
    expect(
      find.text('Solo tú puedes ver el contenido hasta la fecha de apertura.'),
      findsOneWidget,
    );
    expect(find.text('Video'), findsOneWidget);
    expect(find.text('05:30'), findsOneWidget);
    expect(find.text('Nota de voz'), findsOneWidget);
    expect(find.text('01:32'), findsOneWidget);
    expect(find.text('Persona de confianza'), findsOneWidget);
    expect(find.text('Abrir cápsula'), findsNothing);
  });

  testWidgets('bloqueada para quien no es el autor: sin contenido',
      (tester) async {
    await _montar(tester, capsula: _capsula(), uid: 'otra-persona');

    expect(find.text('Abrir en'), findsOneWidget);
    expect(find.text('Sobre esta cápsula'), findsNothing);
    expect(find.text('El contenido se revelará el 13 ago 2046.'), findsOneWidget);
    expect(find.text('Video'), findsNothing);
  });

  testWidgets('cuando llega la fecha se abre con la animación del frasco',
      (tester) async {
    await _montar(
      tester,
      capsula: _capsula(fechaApertura: _ahora.subtract(const Duration(hours: 1))),
    );

    expect(find.text('Se abrió el'), findsOneWidget);
    expect(find.text('Video'), findsNothing);
    await tester.tap(find.text('Abrir cápsula'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2400));
    expect(find.text('¡Tu cápsula se abrió!'), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.text('¡Tu cápsula se abrió!'), findsNothing);
    expect(find.text('Video'), findsOneWidget);
    expect(find.text('Nota de voz'), findsOneWidget);
  });

  testWidgets('cápsula inexistente muestra un estado vacío', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          proveedorRepositorioAutenticacion
              .overrideWithValue(RepositorioAutenticacionFalso()),
          proveedorRepositorioCapsulas
              .overrideWithValue(RepositorioCapsulasFalso()),
        ],
        child: const MaterialApp(home: PantallaDetalleCapsula(idCapsula: 'x')),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Esta cápsula no existe o aún no puedes verla.'),
      findsOneWidget,
    );
  });
}
