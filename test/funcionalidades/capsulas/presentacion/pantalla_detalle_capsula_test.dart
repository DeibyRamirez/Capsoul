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

import '../../../ayudantes/app_prueba.dart';
import '../../../ayudantes/falsos.dart';
import '../../../ayudantes/falsos_capsulas.dart';
import '../../../ayudantes/falsos_recuerdos.dart';

final _ahora = DateTime(2026, 10, 3, 10);

Capsula _capsula({
  DateTime? fechaApertura,
  EstadoCapsula estado = EstadoCapsula.programada,
  DateTime? liberadaEn,
  List<String> destinatariosUsuarioIds = const ['invitado-uid'],
}) =>
    Capsula(
      id: 'c1',
      autorId: 'uid-123',
      titulo: 'Para Jacobo',
      mensaje: 'Quiero que sepas que eres lo mejor que me ha pasado.',
      estado: estado,
      liberadaEn: liberadaEn,
      creadoEn: DateTime(2026, 8, 13),
      fechaApertura: fechaApertura ?? DateTime(2046, 8, 13, 8),
      destinatariosUsuarioIds: destinatariosUsuarioIds,
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
      child: envoltorioPrueba(
        MaterialApp(
          theme: TemaApp.claro,
          home: const PantallaDetalleCapsula(idCapsula: 'c1'),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
      'para mí mismo sellada: el autor no ve mensaje ni contenido',
      (tester) async {
    await _montar(
      tester,
      capsula: _capsula(destinatariosUsuarioIds: ['uid-123']),
    );

    expect(find.text('Abrir en'), findsOneWidget);
    expect(find.text('Sobre esta cápsula'), findsNothing);
    expect(
      find.text('Solo tú puedes ver el contenido hasta la fecha de apertura.'),
      findsNothing,
    );
    expect(find.text('El contenido se revelará el 13 ago 2046.'), findsOneWidget);
    expect(find.text('Video'), findsNothing);
    expect(find.text('Nota de voz'), findsNothing);
  });

  testWidgets(
      'para mí mismo con fecha pasada sin liberar: sin contenido para el autor',
      (tester) async {
    await _montar(
      tester,
      capsula: _capsula(
        destinatariosUsuarioIds: ['uid-123'],
        fechaApertura: _ahora.subtract(const Duration(hours: 1)),
      ),
    );

    expect(find.text('Aún no liberada'), findsOneWidget);
    expect(find.text('Video'), findsNothing);
    expect(find.text('Nota de voz'), findsNothing);
  });

  testWidgets('sellada enviada: el autor ve candado, cuenta regresiva y contenido',
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
    await tester.scrollUntilVisible(
      find.text('Persona de confianza'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Persona de confianza'), findsOneWidget);
    expect(find.text('Abrir cápsula'), findsNothing);
  });

  testWidgets(
      'programada: Gestionar usa filas en tarjeta, sin botones ancho completo',
      (tester) async {
    await _montar(
      tester,
      capsula: _capsula(estado: EstadoCapsula.programada),
    );

    await tester.scrollUntilVisible(
      find.text('Gestionar'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Compartir enlace'), findsOneWidget);
    expect(find.text('Editar'), findsOneWidget);
    expect(find.text('Cancelar programación'), findsOneWidget);
    expect(find.text('Eliminar cápsula'), findsNothing);
    expect(find.byType(OutlinedButton), findsNothing);
  });

  testWidgets('bloqueada para quien no es el autor: sin contenido',
      (tester) async {
    await _montar(tester, capsula: _capsula(), uid: 'otra-persona');

    expect(find.text('Abrir en'), findsOneWidget);
    expect(find.text('Sobre esta cápsula'), findsNothing);
    expect(find.text('El contenido se revelará el 13 ago 2046.'), findsOneWidget);
    expect(find.text('Video'), findsNothing);
  });

  testWidgets('fecha pasada sin liberar: el autor sigue viendo el sello',
      (tester) async {
    await _montar(
      tester,
      capsula: _capsula(fechaApertura: _ahora.subtract(const Duration(hours: 1))),
    );

    expect(find.text('Abrir en'), findsOneWidget);
    expect(find.text('Aún no liberada'), findsOneWidget);
    expect(find.text('Se abrió el'), findsNothing);
    expect(find.text('Ya puedes abrirla'), findsNothing);
    expect(find.text('Abrir cápsula'), findsNothing);
    expect(find.text('Video'), findsOneWidget);
    expect(find.text('Nota de voz'), findsOneWidget);
  });

  testWidgets('fecha pasada sin liberar: el invitado no puede abrir',
      (tester) async {
    await _montar(
      tester,
      capsula: _capsula(fechaApertura: _ahora.subtract(const Duration(hours: 1))),
      uid: 'invitado-uid',
    );

    expect(find.text('Abrir cápsula'), findsNothing);
    expect(find.text('Ya puedes abrirla'), findsNothing);
    expect(find.text('Video'), findsNothing);
  });

  testWidgets('liberada: el invitado abre con la animación del frasco',
      (tester) async {
    await _montar(
      tester,
      capsula: _capsula(
        fechaApertura: _ahora.subtract(const Duration(hours: 1)),
        estado: EstadoCapsula.liberada,
        liberadaEn: _ahora.subtract(const Duration(minutes: 5)),
      ),
      uid: 'invitado-uid',
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
        child: envoltorioPrueba(
          const MaterialApp(home: PantallaDetalleCapsula(idCapsula: 'x')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Esta cápsula no existe o aún no puedes verla.'),
      findsOneWidget,
    );
  });
}
