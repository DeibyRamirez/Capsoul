import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

import '../infraestructura/cliente_postgrest.dart';

/// Registro de tokens FCM en `dispositivos_push`.
abstract interface class RegistroDispositivosPush {
  Future<void> registrarToken(String tokenFcm);

  /// Borra el token de este dispositivo. [uid] permite hacerlo cuando la
  /// sesión ya se cerró y [uidActual] ya no está.
  Future<void> eliminarToken(String tokenFcm, {String? uid});
}

String? plataformaPushActual() {
  if (kIsWeb) return null;
  if (Platform.isAndroid) return 'android';
  if (Platform.isIOS) return 'ios';
  return null;
}

/// Implementación con PostgREST. El alta pasa por la RPC
/// `registrar_dispositivo_push` (security definer): hace upsert por
/// `token_fcm`, reasigna el token si el teléfono cambió de cuenta y reactiva
/// los avisos recientes que fallaron por falta de token.
class RepositorioDispositivosPush implements RegistroDispositivosPush {
  RepositorioDispositivosPush(
    this._cliente, {
    required this.uidActual,
    String? Function()? plataforma,
  }) : _plataforma = plataforma ?? plataformaPushActual;

  final ClientePostgrest _cliente;
  final String? Function() uidActual;
  final String? Function() _plataforma;

  @override
  Future<void> registrarToken(String tokenFcm) async {
    final uid = uidActual();
    final plataforma = _plataforma();
    if (uid == null || plataforma == null || tokenFcm.isEmpty) return;
    await _cliente.rpc(
      'registrar_dispositivo_push',
      parametros: {'p_token': tokenFcm, 'p_plataforma': plataforma},
    );
  }

  @override
  Future<void> eliminarToken(String tokenFcm, {String? uid}) async {
    final dueno = uid ?? uidActual();
    if (dueno == null || tokenFcm.isEmpty) return;
    await _cliente
        .from('dispositivos_push')
        .eliminar()
        .eq('usuario_id', dueno)
        .eq('token_fcm', tokenFcm)
        .ejecutar();
  }
}
