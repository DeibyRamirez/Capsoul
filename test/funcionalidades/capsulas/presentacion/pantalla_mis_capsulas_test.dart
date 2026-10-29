import 'package:capsoul/funcionalidades/autenticacion/aplicacion/proveedores_autenticacion.dart';
import 'package:capsoul/funcionalidades/autenticacion/dominio/usuario_app.dart';
import 'package:capsoul/funcionalidades/capsulas/aplicacion/proveedores_capsulas.dart';
import 'package:capsoul/funcionalidades/capsulas/dominio/capsula.dart';
import 'package:capsoul/funcionalidades/capsulas/dominio/capsula_recibida.dart';
import 'package:capsoul/funcionalidades/capsulas/dominio/estado_capsula.dart';
import 'package:capsoul/funcionalidades/capsulas/presentacion/pantalla_mis_capsulas.dart';
import 'package:capsoul/funcionalidades/capsulas/presentacion/vista_capsulas_tab.dart';
import 'package:capsoul/nucleo/enrutador/rutas_app.dart';
import 'package:capsoul/nucleo/errores/fallo_app.dart';
import 'package:capsoul/nucleo/tema/tema_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../ayudantes/falsos.dart';

void main() {
  final ahora = DateTime(2026, 6, 1, 9);

  Capsula propia({
    required String id,
    required String titulo,
    List<String> destinatarios = const ['amigo'],
    bool correo = false,
  }) =>
      Capsula(
        id: id,
        autorId: 'yo',
        titulo: titulo,
        estado: EstadoCapsula.programada,
        creadoEn: DateTime(2026, 1, 1),
        fechaApertura: DateTime(2030, 1, 1, 8),
        destinatariosUsuarioIds: destinatarios,
        tieneCorreoExterno: correo,
      );

  final enviada = propia(id: 'm1', titulo: 'Para un amigo');
  final soloMia = propia(
    id: 'm2',
    titulo: 'Solo para mí',
    destinatarios: const ['yo'],
  );
  final mixta = propia(
    id: 'm3',
    titulo: 'Para los dos',
    destinatarios: const ['yo', 'amigo'],
  );

  final recibida = CapsulaRecibida(
    id: 'r1',
    autorId: 'otro',
    autorNombre: 'Ana',
    titulo: 'Sorpresa',
    fechaApertura: DateTime(2030, 1, 1),
    estado: EstadoCapsula.programada,
  );
  final ecoPropia = CapsulaRecibida(
    id: 'm2',
    autorId: 'yo',
    autorNombre: 'Yo',
    titulo: 'Solo para mí',
    fechaApertura: DateTime(2030, 1, 1),
    estado: EstadoCapsula.programada,
  );

  Widget app({
    VistaCapsulasTab vista = VistaCapsulasTab.misCapsulas,
    Future<List<Capsula>> Function()? mis,
    Future<List<CapsulaRecibida>> Function()? recibidasDe,
    String? rutaDetalle,
  }) {
    final inicio = PantallaMisCapsulas(vistaInicial: vista);
    final detalle = rutaDetalle;
    return ProviderScope(
      overrides: [
        proveedorRepositorioAutenticacion.overrideWithValue(
          RepositorioAutenticacionFalso(
            usuarioInicial: const UsuarioApp(
              uid: 'yo',
              correo: 'yo@capsoul.app',
              correoVerificado: true,
            ),
          ),
        ),
        proveedorMisCapsulas.overrideWith(
          (_) => mis?.call() ?? Future.value([enviada, soloMia, mixta]),
        ),
        proveedorCapsulasRecibidas.overrideWith(
          (_) => recibidasDe?.call() ?? Future.value([recibida, ecoPropia]),
        ),
        proveedorReloj.overrideWithValue(() => ahora),
      ],
      child: detalle == null
          ? MaterialApp(theme: TemaApp.claro, home: inicio)
          : MaterialApp.router(
              theme: TemaApp.claro,
              routerConfig: GoRouter(
                initialLocation: RutasApp.capsulas,
                routes: [
                  GoRoute(
                    path: RutasApp.capsulas,
                    builder: (_, _) => inicio,
                  ),
                  GoRoute(
                    path: detalle,
                    builder: (_, state) =>
                        Text('detalle-${state.pathParameters['id']}'),
                  ),
                ],
              ),
            ),
    );
  }

  testWidgets('pestaña Mis cápsulas muestra enviadas y no las solo mías',
      (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('Para un amigo'), findsOneWidget);
    expect(find.text('Para los dos'), findsOneWidget);
    expect(find.text('Solo para mí'), findsNothing);
    expect(find.text('Sorpresa'), findsNothing);
    expect(find.text('Para mí mismo'), findsOneWidget);
  });

  testWidgets('pestaña Para mí mismo no repite las enviadas', (tester) async {
    await tester.pumpWidget(app(vista: VistaCapsulasTab.paraMiMismo));
    await tester.pumpAndSettle();

    expect(find.text('Solo para mí'), findsWidgets);
    expect(find.text('Para un amigo'), findsNothing);
    expect(find.text('Para los dos'), findsNothing);
  });

  testWidgets('pestaña Para mí oculta el eco de mis propias cápsulas',
      (tester) async {
    await tester.pumpWidget(app(vista: VistaCapsulasTab.paraMi));
    await tester.pumpAndSettle();

    expect(find.text('Cápsula para ti'), findsOneWidget);
    expect(find.text('Solo para mí'), findsNothing);
    expect(find.text('Para un amigo'), findsNothing);
  });

  testWidgets('cada pestaña tiene su estado vacío', (tester) async {
    await tester.pumpWidget(
      app(
        mis: () async => <Capsula>[],
        recibidasDe: () async => <CapsulaRecibida>[],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Aún no tienes cápsulas.'), findsOneWidget);

    await tester.tap(find.text('Para mí mismo'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Activa «También para mí»'),
      findsOneWidget,
    );

    await tester.tap(find.text('Para mí'));
    await tester.pumpAndSettle();
    expect(find.textContaining('otras personas'), findsOneWidget);
  });

  testWidgets('muestra carga y error de la pestaña activa', (tester) async {
    await tester.pumpWidget(
      app(
        mis: () => Future<List<Capsula>>.error(Exception('red')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(kMensajeErrorInesperado), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);

    await tester.tap(find.text('Para mí'));
    await tester.pumpAndSettle();
    expect(find.text('Cápsula para ti'), findsOneWidget);
  });

  testWidgets('la tarjeta abre el detalle', (tester) async {
    await tester.pumpWidget(
      app(rutaDetalle: '/capsulas/:id'),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Para un amigo'));
    await tester.pumpAndSettle();
    expect(find.text('detalle-m1'), findsOneWidget);
  });
}
