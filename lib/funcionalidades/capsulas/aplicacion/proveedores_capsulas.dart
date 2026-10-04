import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../autenticacion/aplicacion/proveedores_autenticacion.dart';
import '../datos/acceso_tablas_capsulas.dart';
import '../datos/repositorio_capsulas_supabase.dart';
import '../dominio/capsula.dart';
import '../dominio/repositorio_capsulas.dart';

/// Repositorio de cápsulas inyectable (se sobrescribe en las pruebas).
final proveedorRepositorioCapsulas = Provider<RepositorioCapsulas>((ref) {
  final autenticacion = ref.watch(proveedorRepositorioAutenticacion);
  return RepositorioCapsulasSupabase(
    acceso: AccesoTablasCapsulasSupabase(),
    uidActual: () => autenticacion.usuarioActual?.uid,
  );
});

/// Reloj inyectable para la cuenta regresiva y las validaciones de fecha.
final proveedorReloj = Provider<DateTime Function()>((ref) => DateTime.now);

/// Cápsulas creadas por el usuario.
final proveedorMisCapsulas = FutureProvider.autoDispose<List<Capsula>>(
  (ref) => ref.watch(proveedorRepositorioCapsulas).listarMisCapsulas(),
);

/// Una cápsula con sus elementos.
final proveedorCapsula = FutureProvider.autoDispose.family<Capsula?, String>(
  (ref, id) => ref.watch(proveedorRepositorioCapsulas).obtenerCapsula(id),
);
