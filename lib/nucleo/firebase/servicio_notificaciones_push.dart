import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

import 'coordinador_avisos_push.dart';
import 'fuente_firebase_push.dart';
import 'presentador_avisos_android.dart';

export 'coordinador_avisos_push.dart' show RegistradorTokenPush, SesionAvisosPush;

/// Arranca FCM en Android/iOS: permiso, canal, token y toque del aviso.
///
/// En pruebas se pueden inyectar [fuente] y [presentador]. Si no, usa Firebase
/// y el canal nativo. Desktop y web no hacen nada.
Future<SesionAvisosPush?> inicializarNotificacionesPush({
  RegistradorTokenPush? alRegistrarToken,
  void Function(String ruta)? alAbrirRuta,
  FuenteMensajesPush? fuente,
  PresentadorAvisos? presentador,
  bool? esAndroid,
  bool? esIos,
  int? sdkAndroid,
}) async {
  if (kIsWeb) return null;
  final android = esAndroid ?? Platform.isAndroid;
  final ios = esIos ?? Platform.isIOS;
  if (!android && !ios) return null;

  final presentadorReal = presentador ?? PresentadorAvisosAndroid();
  final nativo = presentadorReal is PresentadorAvisosAndroid
      ? presentadorReal
      : null;
  if (nativo != null && alAbrirRuta != null) {
    nativo.escucharToques(alAbrirRuta);
  }
  var sdk = sdkAndroid ?? 0;
  if (sdkAndroid == null && android && nativo != null) {
    sdk = await nativo.leerSdk();
  }

  final sesion = SesionAvisosPush(
    fuente: fuente ?? FuenteFirebasePush(),
    presentador: presentadorReal,
    alRegistrarToken: alRegistrarToken ?? (_) async {},
    alAbrirRuta: alAbrirRuta ?? (_) {},
    esAndroid: android,
    esIos: ios,
    sdkAndroid: sdk,
  );
  await sesion.iniciar();
  return sesion;
}
