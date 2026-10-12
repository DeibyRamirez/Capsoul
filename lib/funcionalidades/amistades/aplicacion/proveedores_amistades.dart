import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/infraestructura/proveedores_infraestructura.dart';
import '../../autenticacion/aplicacion/proveedores_autenticacion.dart';
import '../datos/acceso_tablas_amistades.dart';
import '../datos/repositorio_amistades_supabase.dart';
import '../dominio/amigo.dart';
import '../dominio/repositorio_amistades.dart';

final proveedorRepositorioAmistades = Provider<RepositorioAmistades>((ref) {
  final autenticacion = ref.watch(proveedorRepositorioAutenticacion);
  return RepositorioAmistadesSupabase(
    acceso: AccesoTablasAmistadesPostgrest(ref.watch(proveedorClientePostgrest)),
    uidActual: () => autenticacion.usuarioActual?.uid,
  );
});

final proveedorMisAmigos = FutureProvider.autoDispose<List<Amigo>>(
  (ref) => ref.watch(proveedorRepositorioAmistades).listarAmigos(),
);

final proveedorSolicitudesAmistad =
    FutureProvider.autoDispose<List<SolicitudAmistad>>(
  (ref) => ref.watch(proveedorRepositorioAmistades).listarSolicitudesPendientes(),
);
