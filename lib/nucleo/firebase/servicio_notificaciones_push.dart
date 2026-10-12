import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

typedef RegistradorTokenPush = Future<void> Function(String token);

/// Inicializa FCM en Android/iOS y enlaza el token con [alRegistrarToken].
Future<void> inicializarNotificacionesPush({
  RegistradorTokenPush? alRegistrarToken,
  Future<void> Function(String token)? alPerderToken,
}) async {
  if (kIsWeb) return;
  if (!Platform.isAndroid && !Platform.isIOS) return;

  Future<void> publicarToken(String? token) async {
    if (token == null || token.isEmpty || alRegistrarToken == null) return;
    try {
      await alRegistrarToken(token);
    } catch (error, traza) {
      debugPrint('Capsoul: no se pudo registrar el token push: $error');
      debugPrintStack(stackTrace: traza);
    }
  }

  try {
    await FirebaseMessaging.instance.requestPermission();
    final token = await FirebaseMessaging.instance.getToken();
    await publicarToken(token);
    FirebaseMessaging.instance.onTokenRefresh.listen(publicarToken);
    if (alPerderToken != null) {
      // No hay callback nativo de borrado; se limpia en logout del usuario.
    }
  } catch (error, trazaPila) {
    debugPrint('Capsoul: no se pudo inicializar FCM: $error');
    debugPrintStack(stackTrace: trazaPila);
  }
}
