import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../datos/repositorio_autenticacion_firebase.dart';
import '../dominio/repositorio_autenticacion.dart';
import '../dominio/usuario_app.dart';

/// Repositorio de autenticación inyectable (se sobrescribe en las pruebas).
final proveedorRepositorioAutenticacion = Provider<RepositorioAutenticacion>(
  (ref) => RepositorioAutenticacionFirebase(),
);

/// Sesión actual. `null` significa sin sesión.
final proveedorEstadoAutenticacion = StreamProvider<UsuarioApp?>(
  (ref) =>
      ref.watch(proveedorRepositorioAutenticacion).cambiosEstadoAutenticacion(),
);
