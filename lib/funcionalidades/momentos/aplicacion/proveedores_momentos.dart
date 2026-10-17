import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/infraestructura/proveedores_infraestructura.dart';
import '../../autenticacion/aplicacion/proveedores_autenticacion.dart';
import '../datos/acceso_tablas_momentos.dart';
import '../datos/repositorio_momentos_supabase.dart';
import '../dominio/momento.dart';
import '../dominio/repositorio_momentos.dart';

final proveedorRepositorioMomentos = Provider<RepositorioMomentos>((ref) {
  final autenticacion = ref.watch(proveedorRepositorioAutenticacion);
  return RepositorioMomentosSupabase(
    acceso: AccesoTablasMomentosPostgrest(ref.watch(proveedorClientePostgrest)),
    uidActual: () => autenticacion.usuarioActual?.uid,
  );
});

final proveedorMomentos = FutureProvider.autoDispose<List<Momento>>(
  (ref) => ref.watch(proveedorRepositorioMomentos).listar(),
);

final proveedorMomento = FutureProvider.autoDispose.family<Momento?, String>(
  (ref, id) => ref.watch(proveedorRepositorioMomentos).obtener(id),
);
