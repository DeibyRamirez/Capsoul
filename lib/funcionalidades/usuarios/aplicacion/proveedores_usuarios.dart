import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/infraestructura/proveedores_infraestructura.dart';
import '../datos/acceso_tabla_usuarios.dart';
import '../datos/repositorio_usuarios_supabase.dart';
import '../dominio/repositorio_usuarios.dart';

final proveedorRepositorioUsuarios = Provider<RepositorioUsuarios>((ref) {
  final repositorio = RepositorioUsuariosSupabase(
    AccesoTablaUsuariosPostgrest(ref.watch(proveedorClientePostgrest)),
  );
  ref.onDispose(repositorio.liberarRecursos);
  return repositorio;
});
