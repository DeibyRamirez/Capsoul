import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderOrFamily;

import '../../../nucleo/infraestructura/configuracion_backend.dart';
import '../../../nucleo/infraestructura/proveedores_infraestructura.dart';
import '../../autenticacion/aplicacion/proveedores_autenticacion.dart';
import '../datos/acceso_tablas_amistades.dart';
import '../datos/cambios_amistades.dart';
import '../datos/repositorio_amistades_supabase.dart';
import '../dominio/amigo.dart';
import '../dominio/repositorio_amistades.dart';

export '../../../nucleo/firebase/aviso_push.dart'
    show tipoAvisoSolicitudAmistad;

final proveedorRepositorioAmistades = Provider<RepositorioAmistades>((ref) {
  final autenticacion = ref.watch(proveedorRepositorioAutenticacion);
  return RepositorioAmistadesSupabase(
    acceso: AccesoTablasAmistadesPostgrest(
      ref.watch(proveedorClientePostgrest),
    ),
    uidActual: () => autenticacion.usuarioActual?.uid,
  );
});

final proveedorMisAmigos = FutureProvider.autoDispose<List<Amigo>>(
  (ref) => ref.watch(proveedorRepositorioAmistades).listarAmigos(),
);

final proveedorSolicitudesAmistad =
    FutureProvider.autoDispose<List<SolicitudAmistad>>(
      (ref) => ref
          .watch(proveedorRepositorioAmistades)
          .listarSolicitudesPendientes(),
    );

/// Solicitudes pendientes que recibí. Alimenta el badge de «Amigos».
final proveedorConteoSolicitudesPendientes = Provider.autoDispose<int>(
  (ref) => ref.watch(proveedorSolicitudesAmistad).value?.length ?? 0,
);

/// Vuelve a pedir solicitudes y amigos (push, tiempo real o al volver).
void refrescarAmistades(void Function(ProviderOrFamily) invalidar) {
  invalidar(proveedorSolicitudesAmistad);
  invalidar(proveedorMisAmigos);
}

final proveedorFuenteCambiosAmistades = Provider<FuenteCambiosAmistades>(
  (ref) => ConfiguracionBackend.esVps
      ? const FuenteCambiosAmistadesInactiva()
      : FuenteCambiosAmistadesSupabase(),
);

/// Mientras alguien lo observe, escucha `amistades` (receptor_id = uid) y
/// refresca solicitudes y amigos. Cierra el canal en onDispose.
final proveedorEscuchaCambiosAmistades = Provider<void>((ref) {
  final uid = ref.watch(proveedorEstadoAutenticacion).value?.uid;
  if (uid == null) return;
  final suscripcion = ref
      .watch(proveedorFuenteCambiosAmistades)
      .escuchar(uid)
      .listen((_) => refrescarAmistades(ref.invalidate));
  ref.onDispose(() => unawaited(suscripcion.cancel()));
});
