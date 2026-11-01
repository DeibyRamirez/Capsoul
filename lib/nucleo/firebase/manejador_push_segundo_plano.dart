import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

bool _segundoPlanoRegistrado = false;

/// Segundo plano y app cerrada.
///
/// Cápsulas, legado y retos traen bloque `notification`: el sistema los
/// muestra en el canal `capsoul_avisos` y este manejador no duplica.
/// La solicitud de amistad va solo en `data`; la pinta `ServicioAvisosFcm`
/// con Aceptar y Rechazar.
@pragma('vm:entry-point')
Future<void> manejadorPushEnSegundoPlano(RemoteMessage mensaje) async {
  final tieneAviso = mensaje.notification != null || mensaje.data['ruta'] != null;
  if (!tieneAviso) return;
}

/// Se registra una sola vez. iOS queda enlazado aunque APNs se configure después.
void registrarManejadorPushEnSegundoPlano() {
  if (_segundoPlanoRegistrado || kIsWeb) return;
  try {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    FirebaseMessaging.onBackgroundMessage(manejadorPushEnSegundoPlano);
    _segundoPlanoRegistrado = true;
  } catch (error, traza) {
    debugPrint('Capsoul: no se registró el aviso en segundo plano: $error');
    debugPrintStack(stackTrace: traza);
  }
}
