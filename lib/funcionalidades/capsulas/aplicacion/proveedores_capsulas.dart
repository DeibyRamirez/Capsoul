import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/infraestructura/proveedores_infraestructura.dart';
import '../../autenticacion/aplicacion/proveedores_autenticacion.dart';
import '../datos/acceso_tablas_capsulas.dart';
import '../datos/repositorio_capsulas_supabase.dart';
import '../dominio/capsula.dart';
import '../dominio/repositorio_capsulas.dart';

final proveedorRepositorioCapsulas = Provider<RepositorioCapsulas>((ref) {
  final autenticacion = ref.watch(proveedorRepositorioAutenticacion);
  return RepositorioCapsulasSupabase(
    acceso: AccesoTablasCapsulasPostgrest(ref.watch(proveedorClientePostgrest)),
    uidActual: () => autenticacion.usuarioActual?.uid,
  );
});

final proveedorReloj = Provider<DateTime Function()>((ref) => DateTime.now);

final proveedorMisCapsulas = FutureProvider.autoDispose<List<Capsula>>(
  (ref) => ref.watch(proveedorRepositorioCapsulas).listarMisCapsulas(),
);

final proveedorCapsula = FutureProvider.autoDispose.family<Capsula?, String>(
  (ref, id) => ref.watch(proveedorRepositorioCapsulas).obtenerCapsula(id),
);
