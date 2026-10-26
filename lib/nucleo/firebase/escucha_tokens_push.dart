import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../funcionalidades/autenticacion/aplicacion/proveedores_autenticacion.dart';
import '../enlaces/enlace_capsoul.dart';
import '../enlaces/enlace_pendiente.dart';
import '../enlaces/proveedor_enlace_pendiente.dart';
import '../enrutador/enrutador_app.dart';
import '../infraestructura/proveedores_infraestructura.dart';
import 'destino_aviso.dart';
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

/// Registra el token FCM y abre la cápsula cuando el usuario toca el aviso.
class EscuchaTokensPush extends ConsumerStatefulWidget {
  const EscuchaTokensPush({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<EscuchaTokensPush> createState() => _EstadoEscuchaTokensPush();
}

class _EstadoEscuchaTokensPush extends ConsumerState<EscuchaTokensPush> {
  var _inicializado = false;
  SesionAvisosPush? _sesion;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _enlazarFcm());
  }

  @override
  void dispose() {
    _sesion?.cerrar();
    super.dispose();
  }

  Future<void> _enlazarFcm() async {
    if (_inicializado) return;
    _inicializado = true;
    final repo = ref.read(proveedorRepositorioDispositivosPush);
    _sesion = await inicializarNotificacionesPush(
      alRegistrarToken: repo.registrarToken,
      alAbrirRuta: _abrirRuta,
    );
  }

  void _abrirRuta(String ruta) {
    final destino = destinoInternoDeAviso(ruta);
    if (destino == null) return;
    final sesion = ref.read(proveedorEstadoAutenticacion).value;
    if (sesion == null) {
      final uri = Uri.tryParse(ruta);
      final id = uri == null ? null : EnlaceCapsoul.idCapsulaDesde(uri);
      if (id != null) {
        ref.read(proveedorEnlacePendiente.notifier).guardar(
              EnlacePendienteCapsula(id),
            );
      }
      return;
    }
    ref.read(proveedorEnrutadorApp).push(destino);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
