import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/infraestructura/proveedores_infraestructura.dart';
import '../../autenticacion/aplicacion/proveedores_autenticacion.dart';
import '../datos/acceso_tablas_resumen_inicio.dart';
import '../datos/repositorio_resumen_inicio_supabase.dart';
import '../dominio/repositorio_resumen_inicio.dart';
import '../dominio/resumen_inicio.dart';

final proveedorRepositorioResumenInicio = Provider<RepositorioResumenInicio>(
  (ref) => RepositorioResumenInicioSupabase(
    AccesoTablasResumenInicioPostgrest(ref.watch(proveedorClientePostgrest)),
  ),
);

final proveedorResumenInicio = FutureProvider.autoDispose<ResumenInicio>((
  ref,
) async {
  final uid = ref.watch(
    proveedorEstadoAutenticacion.select((estado) => estado.value?.uid),
  );
  if (uid == null) return ResumenInicio.vacio;
  return ref.watch(proveedorRepositorioResumenInicio).leerResumen(uid);
});
