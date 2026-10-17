import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/infraestructura/proveedores_infraestructura.dart';
import '../../autenticacion/aplicacion/proveedores_autenticacion.dart';
import '../datos/acceso_tablas_retos.dart';
import '../datos/repositorio_retos_supabase.dart';
import '../dominio/repositorio_retos.dart';
import '../dominio/reto.dart';

final proveedorRepositorioRetos = Provider<RepositorioRetos>((ref) {
  return RepositorioRetosSupabase(
    AccesoTablasRetosPostgrest(ref.watch(proveedorClientePostgrest)),
  );
});

final proveedorListaRetos = FutureProvider.autoDispose<List<Reto>>((ref) async {
  final uid = ref.watch(
    proveedorEstadoAutenticacion.select((estado) => estado.value?.uid),
  );
  if (uid == null) return const [];
  return ref.watch(proveedorRepositorioRetos).listar();
});

final proveedorRetosPendientes = FutureProvider.autoDispose<int>((ref) async {
  final uid = ref.watch(
    proveedorEstadoAutenticacion.select((estado) => estado.value?.uid),
  );
  if (uid == null) return 0;
  return ref.watch(proveedorRepositorioRetos).contarPendientes();
});
