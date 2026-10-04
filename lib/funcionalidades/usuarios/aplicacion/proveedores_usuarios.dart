import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../datos/acceso_tabla_usuarios.dart';
import '../datos/repositorio_usuarios_supabase.dart';
import '../dominio/repositorio_usuarios.dart';

/// Repositorio de usuarios inyectable (se sobrescribe en las pruebas).
final proveedorRepositorioUsuarios = Provider<RepositorioUsuarios>((ref) {
  final repositorio = RepositorioUsuariosSupabase(AccesoTablaUsuariosSupabase());
  ref.onDispose(repositorio.liberarRecursos);
  return repositorio;
});
