import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'aviso_push.dart';
import 'coordinador_avisos_push.dart';
import 'manejador_push_segundo_plano.dart';
import 'reintento_token_apns.dart';

/// FCM en Android e iOS. El permiso de Android 13 lo pide el presentador nativo.
class FuenteFirebasePush implements FuenteMensajesPush {
  @override
  Future<void> pedirPermisoIos() async {
    await FirebaseMessaging.instance.requestPermission();
  }

  @override
  Future<void> presentarEnPrimerPlanoIos() {
    return FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// En iOS, `getToken` falla si el token APNs aún no existe (primer
  /// arranque, permiso recién concedido). Se espera con reintentos; si no
  /// llega, el token entra después por [renovacionesToken].
  @override
  Future<String?> tokenActual() async {
    final mensajeria = FirebaseMessaging.instance;
    if (!kIsWeb && Platform.isIOS) {
      final apns = await esperarConReintentos(mensajeria.getAPNSToken);
      if (apns == null) {
        debugPrint('Capsoul: token APNs no disponible; se espera onTokenRefresh');
        return null;
      }
    }
    return mensajeria.getToken();
  }

  @override
  Stream<String> get renovacionesToken => FirebaseMessaging.instance.onTokenRefresh;

  @override
  Stream<MensajePush> get enPrimerPlano =>
      FirebaseMessaging.onMessage.map(mensajeDesdeRemote);

  @override
  Stream<MensajePush> get alAbrirDesdeAviso =>
      FirebaseMessaging.onMessageOpenedApp.map(mensajeDesdeRemote);

  @override
  Future<MensajePush?> mensajeQueAbrioLaApp() async {
    final inicial = await FirebaseMessaging.instance.getInitialMessage();
    if (inicial == null) return null;
    return mensajeDesdeRemote(inicial);
  }

  @override
  void registrarManejadorSegundoPlano() {
    registrarManejadorPushEnSegundoPlano();
  }
}

MensajePush mensajeDesdeRemote(RemoteMessage mensaje) {
  final datos = <String, String>{};
  mensaje.data.forEach((clave, valor) {
    datos[clave] = valor.toString();
  });
  return mensajeDesdeMapa(
    titulo: mensaje.notification?.title,
    cuerpo: mensaje.notification?.body,
    datos: datos,
  );
}
