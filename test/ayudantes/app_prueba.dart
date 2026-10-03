import 'package:capsoul/app_capsoul.dart';
import 'package:capsoul/funcionalidades/autenticacion/aplicacion/proveedores_autenticacion.dart';
import 'package:capsoul/funcionalidades/capsulas/aplicacion/proveedores_capsulas.dart';
import 'package:capsoul/funcionalidades/inicio/aplicacion/proveedores_inicio.dart';
import 'package:capsoul/funcionalidades/momentos/aplicacion/proveedores_momentos.dart';
import 'package:capsoul/funcionalidades/recuerdos/aplicacion/proveedores_recuerdos.dart';
import 'package:capsoul/funcionalidades/usuarios/aplicacion/proveedores_usuarios.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'falsos.dart';
import 'falsos_capsulas.dart';
import 'falsos_momentos.dart';
import 'falsos_recuerdos.dart';

/// Fecha fija para las pruebas (3 oct 2026, 10:00 local).
final DateTime ahoraPrueba = DateTime(2026, 10, 3, 10);

/// Monta la [AppCapsoul] real (enrutador real) con repositorios falsos.
Future<void> montarAppCapsoul(
  WidgetTester tester, {
  required RepositorioAutenticacionFalso autenticacion,
  RepositorioUsuariosFalso? usuarios,
  RepositorioResumenInicioFalso? resumen,
  RepositorioCapsulasFalso? capsulas,
  RepositorioRecuerdosFalso? recuerdos,
  RepositorioMomentosFalso? momentos,
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
        proveedorRepositorioResumenInicio.overrideWithValue(
          resumen ?? RepositorioResumenInicioFalso(),
        ),
        proveedorRepositorioCapsulas.overrideWithValue(
          capsulas ?? RepositorioCapsulasFalso(),
        ),
        proveedorRepositorioRecuerdos.overrideWithValue(
          recuerdos ?? RepositorioRecuerdosFalso(),
        ),
        proveedorRepositorioMomentos.overrideWithValue(
          momentos ?? RepositorioMomentosFalso(),
        ),
        proveedorRepositorioUrlsMedio.overrideWithValue(
          RepositorioUrlsMedioFalso(),
        ),
        proveedorArchivosMedio.overrideWithValue(ArchivosMedioFalso()),
        proveedorReloj.overrideWithValue(() => ahoraPrueba),
      ],
      child: const AppCapsoul(),
    ),
  );
  await tester.pumpAndSettle();
}
