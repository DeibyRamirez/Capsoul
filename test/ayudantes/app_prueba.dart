import 'package:capsoul/app_capsoul.dart';
import 'package:capsoul/funcionalidades/autenticacion/aplicacion/proveedores_autenticacion.dart';
import 'package:capsoul/funcionalidades/usuarios/aplicacion/proveedores_usuarios.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'falsos.dart';

/// Monta la [AppCapsoul] real (enrutador real) con repositorios falsos.
Future<void> montarAppCapsoul(
  WidgetTester tester, {
  required RepositorioAutenticacionFalso autenticacion,
  RepositorioUsuariosFalso? usuarios,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        proveedorRepositorioAutenticacion.overrideWithValue(autenticacion),
        proveedorRepositorioUsuarios.overrideWithValue(
          usuarios ?? RepositorioUsuariosFalso(),
        ),
      ],
      child: const AppCapsoul(),
    ),
  );
  await tester.pumpAndSettle();
}
