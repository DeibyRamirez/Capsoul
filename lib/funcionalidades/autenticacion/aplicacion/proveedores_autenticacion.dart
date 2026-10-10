import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/infraestructura/proveedores_infraestructura.dart';
import '../datos/repositorio_autenticacion_supabase.dart';
import '../dominio/repositorio_autenticacion.dart';
import '../dominio/usuario_app.dart';

final proveedorRepositorioAutenticacion = Provider<RepositorioAutenticacion>(
  (ref) => RepositorioAutenticacionSupabase(
    ref.watch(proveedorClienteAutenticacion),
  ),
);

final proveedorEstadoAutenticacion = StreamProvider<UsuarioApp?>(
  (ref) =>
      ref.watch(proveedorRepositorioAutenticacion).cambiosEstadoAutenticacion(),
);

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
