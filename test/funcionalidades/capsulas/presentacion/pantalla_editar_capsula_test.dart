import 'package:capsoul/funcionalidades/capsulas/aplicacion/proveedores_capsulas.dart';
import 'package:capsoul/funcionalidades/capsulas/dominio/capsula.dart';
import 'package:capsoul/funcionalidades/capsulas/dominio/estado_capsula.dart';
import 'package:capsoul/funcionalidades/capsulas/presentacion/pantalla_editar_capsula.dart';
import 'package:capsoul/funcionalidades/autenticacion/aplicacion/proveedores_autenticacion.dart';
import 'package:capsoul/funcionalidades/usuarios/aplicacion/proveedores_usuarios.dart';
import 'package:capsoul/funcionalidades/usuarios/dominio/perfil_usuario.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../ayudantes/app_prueba.dart';
import '../../../ayudantes/falsos.dart';
import '../../../ayudantes/falsos_capsulas.dart';
import '../../../ayudantes/falsos_recuerdos.dart';

void main() {
  testWidgets('carga recuerdos y guarda cambios', (tester) async {
    final capsulas = RepositorioCapsulasFalso();
    final recuerdo = recuerdoPrueba('r1', titulo: 'Playa');
    capsulas.capsulas['c-edit'] = Capsula(
      id: 'c-edit',
      autorId: usuarioPrueba.uid,
      titulo: 'Viejo',
      mensaje: 'Msg',
      fechaApertura: DateTime(2028, 5, 5, 8),
      estado: EstadoCapsula.programada,
      creadoEn: DateTime(2026, 10, 3),
      elementos: [recuerdo],
      destinatariosUsuarioIds: const ['amigo-1'],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          proveedorRepositorioAutenticacion.overrideWithValue(
            RepositorioAutenticacionFalso(usuarioInicial: usuarioPrueba),
          ),
          proveedorRepositorioUsuarios.overrideWithValue(
            RepositorioUsuariosFalso()
              ..perfiles[usuarioPrueba.uid] = PerfilUsuario(
                uid: usuarioPrueba.uid,
                nombreVisible: usuarioPrueba.nombreVisible!,
                correo: usuarioPrueba.correo!,
              ),
          ),
          proveedorRepositorioCapsulas.overrideWithValue(capsulas),
          proveedorReloj.overrideWithValue(() => ahoraPrueba),
        ],
        child: envoltorioPrueba(
          MaterialApp.router(
            routerConfig: GoRouter(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) =>
                      const PantallaEditarCapsula(idCapsula: 'c-edit'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Editar cápsula'), findsOneWidget);
    expect(find.text('Playa'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Actualizado');
    await tester.scrollUntilVisible(
      find.text('Guardar cambios'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    expect(capsulas.actualizaciones, hasLength(1));
    expect(capsulas.actualizaciones.single.titulo, 'Actualizado');
    expect(capsulas.actualizaciones.single.recuerdos, ['r1']);
    expect(capsulas.actualizaciones.single.destinatarios, ['amigo-1']);
  });
}
