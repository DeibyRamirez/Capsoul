import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Inicializa FCM en Android/iOS. No bloquea el arranque si falla.
Future<void> inicializarNotificacionesPush() async {
  if (kIsWeb) return;
  if (!Platform.isAndroid && !Platform.isIOS) {
    debugPrint('Capsoul: FCM no disponible en esta plataforma.');
    return;
  }
  try {
    final token = await FirebaseMessaging.instance.getToken();
    debugPrint('Capsoul: FCM token: $token');
  } catch (error, trazaPila) {
    debugPrint('Capsoul: no se pudo obtener el token FCM: $error');
    debugPrintStack(stackTrace: trazaPila);
  }
}
