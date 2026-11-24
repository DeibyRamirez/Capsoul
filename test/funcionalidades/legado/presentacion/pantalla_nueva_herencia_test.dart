import 'package:capsoul/funcionalidades/amistades/aplicacion/proveedores_amistades.dart';
import 'package:capsoul/funcionalidades/autenticacion/aplicacion/proveedores_autenticacion.dart';
import 'package:capsoul/funcionalidades/capsulas/aplicacion/proveedores_capsulas.dart';
import 'package:capsoul/funcionalidades/capsulas/dominio/capsula.dart';
import 'package:capsoul/funcionalidades/capsulas/dominio/estado_capsula.dart';
import 'package:capsoul/funcionalidades/legado/aplicacion/controlador_nueva_herencia.dart';
import 'package:capsoul/funcionalidades/legado/aplicacion/proveedores_legado.dart';
import 'package:capsoul/funcionalidades/legado/presentacion/pantalla_nueva_herencia.dart';
import 'package:capsoul/nucleo/tema/tema_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../ayudantes/falsos.dart';
import '../../../ayudantes/falsos_amistades.dart';
import '../../../ayudantes/falsos_capsulas.dart';
import '../../../ayudantes/falsos_legado.dart';

void main() {
  testWidgets('al avanzar no se pierden los campos del paso anterior', (
    tester,
  ) async {
    final contenedor = ProviderContainer(
      overrides: [
        proveedorRepositorioLegado.overrideWithValue(RepositorioLegadoFalso()),
        proveedorRepositorioAmistades.overrideWithValue(
          RepositorioAmistadesFalso(),
        ),
        proveedorRepositorioCapsulas.overrideWithValue(
          RepositorioCapsulasFalso(),
        ),
        proveedorEstadoAutenticacion.overrideWith(
          (ref) => Stream.value(usuarioPrueba),
        ),
      ],
    );
    addTearDown(contenedor.dispose);
    final escucha = contenedor.listen(
      proveedorControladorNuevaHerencia,
      (_, _) {},
    );
    addTearDown(escucha.close);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: contenedor,
        child: MaterialApp(
          theme: TemaApp.claro,
          home: const PantallaNuevaHerencia(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('campo_descripcion')),
      'Reloj de familia',
    );
    await tester.ensureVisible(find.text('Continuar'));
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    final borrador = contenedor.read(proveedorControladorNuevaHerencia);
    expect(borrador.paso, 1);
    expect(borrador.descripcion, 'Reloj de familia');
  });

  testWidgets('el wizard solo ofrece fecha programada', (tester) async {
    final legado = RepositorioLegadoFalso();
    final contenedor = ProviderContainer(
      overrides: [
        proveedorRepositorioLegado.overrideWithValue(legado),
        proveedorRepositorioAmistades.overrideWithValue(
          RepositorioAmistadesFalso(),
        ),
        proveedorRepositorioCapsulas.overrideWithValue(
          RepositorioCapsulasFalso(),
        ),
        proveedorEstadoAutenticacion.overrideWith(
          (ref) => Stream.value(usuarioPrueba),
        ),
      ],
    );
    addTearDown(contenedor.dispose);
    final escucha = contenedor.listen(
      proveedorControladorNuevaHerencia,
      (_, _) {},
    );
    addTearDown(escucha.close);

    contenedor.read(proveedorControladorNuevaHerencia.notifier).actualizar(
      BorradorNuevaHerencia(
        paso: 4,
        descripcion: 'Reloj',
        beneficiarioUsuarioId: 'amigo-1',
        mensajePersonal: 'Mensaje',
        tipoActivo: 'Reloj',
        titular: 'Ana',
        valorAproximado: '1000',
        instrucciones: 'Entregar',
        fechaActivacion: DateTime.now().add(const Duration(days: 2)),
      ),
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: contenedor,
        child: MaterialApp(
          theme: TemaApp.claro,
          home: const PantallaNuevaHerencia(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Fecha de apertura'), findsOneWidget);
    expect(find.text('Fecha programada'), findsNothing);
    expect(find.text('Confirmación de persona de confianza'), findsNothing);
    expect(
      find.byKey(const ValueKey('campo_persona_confianza_herencia')),
      findsOneWidget,
    );
  });

  testWidgets('solo lista cápsulas propias y listas para vincular', (
    tester,
  ) async {
    final capsulas = RepositorioCapsulasFalso()
      ..capsulas['propia'] = Capsula(
        id: 'propia',
        autorId: 'uid-123',
        titulo: 'Mi cápsula',
        estado: EstadoCapsula.programada,
        creadoEn: DateTime(2026, 1, 1),
      )
      ..capsulas['ajena'] = Capsula(
        id: 'ajena',
        autorId: 'otro-usuario',
        titulo: 'Cápsula ajena',
        estado: EstadoCapsula.liberada,
        creadoEn: DateTime(2026, 1, 1),
      );

    final contenedor = ProviderContainer(
      overrides: [
        proveedorRepositorioLegado.overrideWithValue(RepositorioLegadoFalso()),
        proveedorRepositorioAmistades.overrideWithValue(
          RepositorioAmistadesFalso(),
        ),
        proveedorRepositorioCapsulas.overrideWithValue(capsulas),
        proveedorEstadoAutenticacion.overrideWith(
          (ref) => Stream.value(usuarioPrueba),
        ),
      ],
    );
    addTearDown(contenedor.dispose);
    final escucha = contenedor.listen(
      proveedorControladorNuevaHerencia,
      (_, _) {},
    );
    addTearDown(escucha.close);
    contenedor.read(proveedorControladorNuevaHerencia.notifier).actualizar(
      BorradorNuevaHerencia(
        paso: 5,
        fechaActivacion: DateTime.now().add(const Duration(days: 2)),
      ),
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: contenedor,
        child: MaterialApp(
          theme: TemaApp.claro,
          home: const PantallaNuevaHerencia(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mi cápsula'), findsOneWidget);
    expect(find.text('Cápsula ajena'), findsNothing);
  });
}
