import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../autenticacion/aplicacion/proveedores_autenticacion.dart';
import '../datos/acceso_tablas_momentos.dart';
import '../datos/repositorio_momentos_supabase.dart';
import '../dominio/momento.dart';
import '../dominio/repositorio_momentos.dart';

/// Repositorio de momentos (se sobrescribe en pruebas).
final proveedorRepositorioMomentos = Provider<RepositorioMomentos>((ref) {
  final autenticacion = ref.watch(proveedorRepositorioAutenticacion);
  return RepositorioMomentosSupabase(
    acceso: AccesoTablasMomentosSupabase(),
    uidActual: () => autenticacion.usuarioActual?.uid,
  );
});

/// Momentos propios.
final proveedorMomentos = FutureProvider.autoDispose<List<Momento>>(
  (ref) => ref.watch(proveedorRepositorioMomentos).listar(),
);

/// Un momento con sus recuerdos.
final proveedorMomento = FutureProvider.autoDispose.family<Momento?, String>(
  (ref, id) => ref.watch(proveedorRepositorioMomentos).obtener(id),
);
