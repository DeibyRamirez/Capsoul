import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../funcionalidades/amistades/aplicacion/proveedores_amistades.dart';
import '../../funcionalidades/capsulas/aplicacion/proveedores_capsulas.dart';

/// Envuelve toda la app (shell raíz). Al volver del segundo plano refresca
/// los avisos de cápsulas y las solicitudes de amistad, y mantiene vivo el
/// canal de tiempo real de `amistades` mientras haya sesión.
class RefrescoAvisosAlVolver extends ConsumerStatefulWidget {
  const RefrescoAvisosAlVolver({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<RefrescoAvisosAlVolver> createState() =>
      _EstadoRefrescoAvisosAlVolver();
}

class _EstadoRefrescoAvisosAlVolver
    extends ConsumerState<RefrescoAvisosAlVolver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(proveedorCapsulasRecibidas);
      refrescarAmistades(ref.invalidate);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(proveedorEscuchaCambiosAmistades);
    return widget.child;
  }
}
