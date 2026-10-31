import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../funcionalidades/amistades/aplicacion/proveedores_amistades.dart';
import '../../funcionalidades/autenticacion/aplicacion/proveedores_autenticacion.dart';
import '../../funcionalidades/autenticacion/dominio/usuario_app.dart';
import '../enlaces/enlace_capsoul.dart';
import '../enlaces/enlace_pendiente.dart';
import '../enlaces/proveedor_enlace_pendiente.dart';
import '../enrutador/enrutador_app.dart';
import '../infraestructura/proveedores_infraestructura.dart';
import 'aviso_push.dart';
import 'destino_aviso.dart';
import 'repositorio_dispositivos_push.dart';
import 'servicio_notificaciones_push.dart';
import 'token_push_actual.dart';
import 'vinculo_token_push.dart';

/// Arranque de FCM inyectable. Las pruebas lo sustituyen para no tocar Firebase.
typedef IniciadorAvisosPush = Future<SesionAvisosPush?> Function({
  required RegistradorTokenPush alRegistrarToken,
  required void Function(String ruta) alAbrirRuta,
  required void Function(MensajePush mensaje) alRecibirEnPrimerPlano,
});

final proveedorRepositorioDispositivosPush = Provider<RegistroDispositivosPush>(
  (ref) {
    final autenticacion = ref.watch(proveedorRepositorioAutenticacion);
    return RepositorioDispositivosPush(
      ref.watch(proveedorClientePostgrest),
      uidActual: () => autenticacion.usuarioActual?.uid,
    );
  },
);

/// Registra el token FCM y abre la cápsula cuando el usuario toca el aviso.
class EscuchaTokensPush extends ConsumerStatefulWidget {
  const EscuchaTokensPush({super.key, required this.child, this.iniciador});

  final Widget child;

  /// Si es nulo, arranca FCM de verdad. Las pruebas pasan un sustituto.
  final IniciadorAvisosPush? iniciador;

  @override
  ConsumerState<EscuchaTokensPush> createState() => _EstadoEscuchaTokensPush();
}

class _EstadoEscuchaTokensPush extends ConsumerState<EscuchaTokensPush> {
  var _inicializado = false;
  SesionAvisosPush? _sesion;
  VinculoTokenPush? _vinculo;
  String? _uidVinculado;

  /// Sesión con la que ya se intentó guardar el token actual.
  String? _uidYaRegistrado;

  @override
  void initState() {
    super.initState();
    _vinculo = VinculoTokenPush(
      registrar: (token) async {
        ref.read(proveedorTokenPushActual.notifier).recordar(token);
        final uid = ref
            .read(proveedorRepositorioAutenticacion)
            .usuarioActual
            ?.uid;
        _uidYaRegistrado = uid;
        await ref
            .read(proveedorRepositorioDispositivosPush)
            .registrarToken(token);
      },
      eliminar: (token, uid) => ref
          .read(proveedorRepositorioDispositivosPush)
          .eliminarToken(token, uid: uid),
    );
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
    final vinculo = _vinculo;
    if (vinculo == null || !mounted) return;
    final iniciador = widget.iniciador;
    if (iniciador != null) {
      _sesion = await iniciador(
        alRegistrarToken: vinculo.recordarToken,
        alAbrirRuta: _abrirRuta,
        alRecibirEnPrimerPlano: _alRecibirEnPrimerPlano,
      );
      return;
    }
    _sesion = await inicializarNotificacionesPush(
      alRegistrarToken: vinculo.recordarToken,
      alAbrirRuta: _abrirRuta,
      alRecibirEnPrimerPlano: _alRecibirEnPrimerPlano,
    );
  }

  /// Con la app abierta, un aviso de solicitud refresca la lista y el badge.
  void _alRecibirEnPrimerPlano(MensajePush mensaje) {
    if (!mounted) return;
    if (mensaje.tipo == tipoAvisoSolicitudAmistad) {
      refrescarAmistades(ref.invalidate);
    }
  }

  bool _sesionAsentada(AsyncValue<UsuarioApp?> estado) =>
      estado.hasValue && !estado.isLoading && !estado.hasError;

  Future<void> _aplicarCambio(String? uidAnterior, String? uidNuevo) async {
    final vinculo = _vinculo;
    if (vinculo == null) return;
    try {
      await vinculo.alCambiarSesion(
        uidAnterior: uidAnterior,
        uidNuevo: uidNuevo,
      );
    } catch (error, traza) {
      debugPrint('Capsoul: no se pudo actualizar el token push: $error');
      debugPrintStack(stackTrace: traza);
    }
  }

  void _abrirRuta(String ruta) {
    final destino = destinoInternoDeAviso(ruta);
    if (destino == null) return;
    final sesion = ref.read(proveedorEstadoAutenticacion).value;
    if (sesion == null) {
      final uri = Uri.tryParse(ruta);
      final id = uri == null ? null : EnlaceCapsoul.idCapsulaDesde(uri);
      if (id != null) {
        ref
            .read(proveedorEnlacePendiente.notifier)
            .guardar(EnlacePendienteCapsula(id));
      }
      return;
    }
    ref.read(proveedorEnrutadorApp).push(destino);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(proveedorEstadoAutenticacion, (_, siguiente) {
      if (!_sesionAsentada(siguiente)) return;
      final uidNuevo = siguiente.value?.uid;
      if (uidNuevo == _uidVinculado) return;
      final uidAnterior = _uidVinculado;
      _uidVinculado = uidNuevo;
      if (uidNuevo == null) _uidYaRegistrado = null;
      if (uidNuevo != null && uidNuevo == _uidYaRegistrado) return;
      unawaited(_aplicarCambio(uidAnterior, uidNuevo));
    });
    return widget.child;
  }
}
