import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../datos/repositorio_autenticacion_supabase.dart';
import '../dominio/repositorio_autenticacion.dart';
import '../dominio/usuario_app.dart';

/// Repositorio de autenticación inyectable (se sobrescribe en las pruebas).
final proveedorRepositorioAutenticacion = Provider<RepositorioAutenticacion>(
  (ref) => RepositorioAutenticacionSupabase(),
);

/// Sesión actual. `null` significa sin sesión.
final proveedorEstadoAutenticacion = StreamProvider<UsuarioApp?>(
  (ref) =>
      ref.watch(proveedorRepositorioAutenticacion).cambiosEstadoAutenticacion(),
);

/// `true` desde que se abre un enlace de recuperación de contraseña hasta que
/// el usuario guarda la nueva contraseña o cancela. El enrutador lo usa para
/// llevarlo a la pantalla de nueva contraseña.
class ControladorModoRecuperacion extends Notifier<bool> {
  @override
  bool build() {
    final suscripcion = ref
        .watch(proveedorRepositorioAutenticacion)
        .enlacesRecuperacion()
        .listen((_) => state = true);
    ref.onDispose(suscripcion.cancel);
    return false;
  }

  void terminar() => state = false;
}

final proveedorModoRecuperacion =
    NotifierProvider<ControladorModoRecuperacion, bool>(
  ControladorModoRecuperacion.new,
);
