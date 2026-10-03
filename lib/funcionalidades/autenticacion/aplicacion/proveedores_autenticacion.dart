import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/supabase/configuracion_supabase.dart';
import '../datos/repositorio_autenticacion_supabase.dart';
import '../dominio/repositorio_autenticacion.dart';
import '../dominio/usuario_app.dart';

/// Repositorio de autenticación inyectable (se sobrescribe en las pruebas).
final proveedorRepositorioAutenticacion = Provider<RepositorioAutenticacion>(
  (ref) => RepositorioAutenticacionSupabase(
    urlRedireccion: ConfiguracionSupabase.urlRedireccion,
  ),
);

/// Sesión actual. `null` significa sin sesión.
final proveedorEstadoAutenticacion = StreamProvider<UsuarioApp?>(
  (ref) =>
      ref.watch(proveedorRepositorioAutenticacion).cambiosEstadoAutenticacion(),
);
