import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

import '../infraestructura/cliente_postgrest.dart';

/// Registro de tokens FCM en `dispositivos_push`.
abstract interface class RegistroDispositivosPush {
  Future<void> registrarToken(String tokenFcm);

  /// Borra el token de este dispositivo. [uid] permite hacerlo cuando la
  /// sesión ya se cerró y [uidActual] ya no está.
  Future<void> eliminarToken(String tokenFcm, {String? uid});
  Future<void> eliminarTodosLosTokensDelUsuario();
}

/// Implementación con PostgREST.
class RepositorioDispositivosPush implements RegistroDispositivosPush {
  RepositorioDispositivosPush(this._cliente, {required this.uidActual});

  final ClientePostgrest _cliente;
  final String? Function() uidActual;

  String? _plataforma() {
    if (kIsWeb) return null;
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return null;
  }

  @override
  Future<void> registrarToken(String tokenFcm) async {
    final uid = uidActual();
    final plataforma = _plataforma();
    if (uid == null || plataforma == null) return;
    final ahora = DateTime.now().toUtc().toIso8601String();
    final cambios = {
      'usuario_id': uid,
      'plataforma': plataforma,
      'ultimo_uso_en': ahora,
    };
    final actualizadas = await _cliente
        .from('dispositivos_push')
        .actualizar(cambios)
        .eq('token_fcm', tokenFcm)
        .select('id');
    if (actualizadas.isEmpty) {
      await _cliente.from('dispositivos_push').insertar({
        ...cambios,
        'token_fcm': tokenFcm,
      });
    }
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

  @override
  Future<void> eliminarTodosLosTokensDelUsuario() async {
    final uid = uidActual();
    if (uid == null) return;
    await _cliente
        .from('dispositivos_push')
        .eliminar()
        .eq('usuario_id', uid)
        .ejecutar();
  }
}
