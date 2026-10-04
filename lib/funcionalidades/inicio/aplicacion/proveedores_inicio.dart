import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../autenticacion/aplicacion/proveedores_autenticacion.dart';
import '../datos/repositorio_resumen_inicio_supabase.dart';
import '../dominio/repositorio_resumen_inicio.dart';
import '../dominio/resumen_inicio.dart';

final proveedorRepositorioResumenInicio = Provider<RepositorioResumenInicio>(
  (ref) => RepositorioResumenInicioSupabase(),
);

/// Conteos de Inicio del usuario con sesión (0 si no hay datos).
final proveedorResumenInicio = FutureProvider.autoDispose<ResumenInicio>((
  ref,
) async {
  final uid = ref.watch(
    proveedorEstadoAutenticacion.select((estado) => estado.value?.uid),
  );
  if (uid == null) return ResumenInicio.vacio;
  return ref.watch(proveedorRepositorioResumenInicio).leerResumen(uid);
});
