import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../infraestructura/proveedores_infraestructura.dart';
import '../../funcionalidades/autenticacion/aplicacion/proveedores_autenticacion.dart';
import 'repositorio_dispositivos_push.dart';
import 'servicio_notificaciones_push.dart';

final proveedorRepositorioDispositivosPush =
    Provider<RegistroDispositivosPush>((ref) {
  final autenticacion = ref.watch(proveedorRepositorioAutenticacion);
  return RepositorioDispositivosPush(
    ref.watch(proveedorClientePostgrest),
    uidActual: () => autenticacion.usuarioActual?.uid,
  );
});

/// Registra el token FCM cuando hay sesión (montar bajo [ProviderScope]).
class EscuchaTokensPush extends ConsumerStatefulWidget {
  const EscuchaTokensPush({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<EscuchaTokensPush> createState() => _EstadoEscuchaTokensPush();
}

class _EstadoEscuchaTokensPush extends ConsumerState<EscuchaTokensPush> {
  var _inicializado = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _enlazarFcm());
  }

  Future<void> _enlazarFcm() async {
    if (_inicializado) return;
    _inicializado = true;
    final repo = ref.read(proveedorRepositorioDispositivosPush);
    await inicializarNotificacionesPush(
      alRegistrarToken: repo.registrarToken,
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
