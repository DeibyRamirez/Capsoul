import 'dart:async';

import 'package:capsoul/funcionalidades/amistades/aplicacion/proveedores_amistades.dart';
import 'package:capsoul/funcionalidades/amistades/datos/cambios_amistades.dart';
import 'package:capsoul/funcionalidades/amistades/dominio/amigo.dart';
import 'package:capsoul/funcionalidades/autenticacion/aplicacion/proveedores_autenticacion.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderOrFamily;
import 'package:flutter_test/flutter_test.dart';

import '../../../ayudantes/falsos.dart';
import '../../../ayudantes/falsos_amistades.dart';

class _RepositorioQueCuenta extends RepositorioAmistadesFalso {
  var lecturasSolicitudes = 0;
  var lecturasAmigos = 0;

  @override
  Future<List<SolicitudAmistad>> listarSolicitudesPendientes() async {
    lecturasSolicitudes++;
    return List<SolicitudAmistad>.of(solicitudes);
  }

  @override
  Future<List<Amigo>> listarAmigos() async {
    lecturasAmigos++;
    return super.listarAmigos();
  }
}

class _FuenteCambiosFalsa implements FuenteCambiosAmistades {
  final controlador = StreamController<void>.broadcast();
  final uidsEscuchados = <String>[];
  var cancelaciones = 0;

  @override
  Stream<void> escuchar(String uidReceptor) {
    uidsEscuchados.add(uidReceptor);
    late final StreamController<void> propio;
    propio = StreamController<void>(
      onListen: () => controlador.stream.listen(propio.add),
      onCancel: () => cancelaciones++,
    );
    return propio.stream;
  }
}

SolicitudAmistad _solicitud(String id) => SolicitudAmistad(
  id: id,
  solicitanteId: 'otro-$id',
  solicitanteNombre: 'Otro $id',
  creadoEn: DateTime(2026, 10, 30),
);

void main() {
  late _RepositorioQueCuenta repositorio;
  late _FuenteCambiosFalsa fuente;
  late ProviderContainer contenedor;

  setUp(() {
    repositorio = _RepositorioQueCuenta();
    fuente = _FuenteCambiosFalsa();
    contenedor = ProviderContainer(
      overrides: [
        proveedorRepositorioAutenticacion.overrideWithValue(
          RepositorioAutenticacionFalso(usuarioInicial: usuarioPrueba),
        ),
        proveedorEstadoAutenticacion.overrideWith(
          (ref) => Stream.value(usuarioPrueba),
        ),
        proveedorRepositorioAmistades.overrideWithValue(repositorio),
        proveedorFuenteCambiosAmistades.overrideWithValue(fuente),
      ],
    );
    addTearDown(contenedor.dispose);
  });

  test('el conteo de pendientes sale de la lista de solicitudes', () async {
    repositorio.solicitudes = [_solicitud('a'), _solicitud('b')];
    final sub = contenedor.listen(
      proveedorConteoSolicitudesPendientes,
      (_, _) {},
    );
    addTearDown(sub.close);
    await contenedor.read(proveedorSolicitudesAmistad.future);
    expect(contenedor.read(proveedorConteoSolicitudesPendientes), 2);
  });

  test('un cambio en tiempo real refresca solicitudes y amigos', () async {
    final sesion = contenedor.listen(proveedorEstadoAutenticacion, (_, _) {});
    final solicitudes = contenedor.listen(
      proveedorSolicitudesAmistad,
      (_, _) {},
    );
    final amigos = contenedor.listen(proveedorMisAmigos, (_, _) {});
    final escucha = contenedor.listen(
      proveedorEscuchaCambiosAmistades,
      (_, _) {},
    );
    addTearDown(sesion.close);
    addTearDown(solicitudes.close);
    addTearDown(amigos.close);
    addTearDown(escucha.close);

    await contenedor.read(proveedorEstadoAutenticacion.future);
    await contenedor.read(proveedorSolicitudesAmistad.future);
    await contenedor.read(proveedorMisAmigos.future);
    await Future<void>.delayed(Duration.zero);
    contenedor.read(proveedorEscuchaCambiosAmistades);
    expect(fuente.uidsEscuchados, [usuarioPrueba.uid]);
    expect(repositorio.lecturasSolicitudes, 1);

    repositorio.solicitudes = [_solicitud('nueva')];
    fuente.controlador.add(null);
    await Future<void>.delayed(Duration.zero);
    await contenedor.read(proveedorSolicitudesAmistad.future);
    await contenedor.read(proveedorMisAmigos.future);

    expect(repositorio.lecturasSolicitudes, 2);
    expect(repositorio.lecturasAmigos, 2);
    expect(contenedor.read(proveedorSolicitudesAmistad).value, hasLength(1));
    expect(contenedor.read(proveedorConteoSolicitudesPendientes), 1);

    contenedor.dispose();
    await Future<void>.delayed(Duration.zero);
    expect(fuente.cancelaciones, 1);
  });

  test('refrescarAmistades invalida solicitudes y amigos', () {
    final invalidados = <ProviderOrFamily>[];
    refrescarAmistades(invalidados.add);
    expect(invalidados, [proveedorSolicitudesAmistad, proveedorMisAmigos]);
  });
}
