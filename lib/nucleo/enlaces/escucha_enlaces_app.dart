import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../funcionalidades/amistades/aplicacion/proveedores_amistades.dart';
import '../../funcionalidades/autenticacion/aplicacion/proveedores_autenticacion.dart';
import '../enrutador/enrutador_app.dart';
import '../enrutador/rutas_app.dart';
import '../firebase/destino_aviso.dart';
import 'enlace_capsoul.dart';
import 'enlace_pendiente.dart';
import 'proveedor_enlace_pendiente.dart';

/// Escucha `capsoul://capsula` y `capsoul://amistad` (no auth: lo maneja Supabase).
class EscuchaEnlacesApp extends ConsumerStatefulWidget {
  const EscuchaEnlacesApp({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<EscuchaEnlacesApp> createState() => _EstadoEscuchaEnlacesApp();
}

class _EstadoEscuchaEnlacesApp extends ConsumerState<EscuchaEnlacesApp> {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _suscripcion;
  var _enlacesIniciados = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _iniciarEnlaces());
  }

  Future<void> _iniciarEnlaces() async {
    if (_enlacesIniciados) return;
    _enlacesIniciados = true;
    final inicial = await _appLinks.getInitialLink();
    if (inicial != null) _procesar(inicial);
    _suscripcion = _appLinks.uriLinkStream.listen(_procesar);
  }

  @override
  void dispose() {
    unawaited(_suscripcion?.cancel());
    super.dispose();
  }

  void _procesar(Uri uri) {
    if (uri.host == 'auth' || uri.path.startsWith('/auth')) return;
    final idCapsula = EnlaceCapsoul.idCapsulaDesde(uri);
    if (idCapsula != null) {
      _navegarCapsula(idCapsula);
      return;
    }
    final token = EnlaceCapsoul.tokenAmistadDesde(uri);
    if (token != null) {
      _navegarAmistad(token);
      return;
    }
    final destino = destinoInternoDeAviso(uri.toString());
    if (destino == null) return;
    final sesion = ref.read(proveedorEstadoAutenticacion).value;
    if (sesion == null || !mounted) return;
    ref.read(proveedorEnrutadorApp).push(destino);
  }

  void _navegarCapsula(String id) {
    final sesion = ref.read(proveedorEstadoAutenticacion).value;
    if (sesion == null) {
      ref.read(proveedorEnlacePendiente.notifier).guardar(
            EnlacePendienteCapsula(id),
          );
      return;
    }
    if (mounted) {
      context.push(RutasApp.detalleCapsulaDe(id));
    }
  }

  Future<void> _navegarAmistad(String token) async {
    final sesion = ref.read(proveedorEstadoAutenticacion).value;
    if (sesion == null) {
      ref.read(proveedorEnlacePendiente.notifier).guardar(
            EnlacePendienteAmistad(token),
          );
      return;
    }
    try {
      await ref.read(proveedorRepositorioAmistades).aceptarInvitacion(token);
      ref.invalidate(proveedorMisAmigos);
      if (!mounted) return;
      context.push(RutasApp.amigos);
    } catch (_) {
      if (mounted) context.push(RutasApp.amigos);
    }
  }

  Future<void> _consumirPendiente() async {
    final pendiente =
        ref.read(proveedorEnlacePendiente.notifier).consumir();
    if (pendiente == null) return;
    switch (pendiente) {
      case EnlacePendienteCapsula(idCapsula: final id):
        _navegarCapsula(id);
      case EnlacePendienteAmistad(token: final token):
        await _navegarAmistad(token);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(proveedorEstadoAutenticacion, (anterior, siguiente) {
      final tenia = anterior?.value != null;
      final tiene = siguiente.value != null;
      if (!tenia && tiene) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) unawaited(_consumirPendiente());
        });
      }
    });
    return widget.child;
  }
}
