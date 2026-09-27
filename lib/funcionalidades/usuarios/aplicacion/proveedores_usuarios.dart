import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../datos/repositorio_usuarios_firestore.dart';
import '../dominio/repositorio_usuarios.dart';

/// Repositorio de usuarios inyectable (se sobrescribe en las pruebas).
final proveedorRepositorioUsuarios = Provider<RepositorioUsuarios>(
  (ref) => RepositorioUsuariosFirestore(),
);
