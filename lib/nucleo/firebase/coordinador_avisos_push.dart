import 'dart:async';

import 'package:flutter/foundation.dart';

import 'aviso_push.dart';
import 'canal_avisos.dart';

/// Origen de tokens y de mensajes. En la app es FCM; las pruebas usan un falso.
abstract interface class FuenteMensajesPush {
  Future<void> pedirPermisoIos();
  Future<void> presentarEnPrimerPlanoIos();
  Future<String?> tokenActual();
  Stream<String> get renovacionesToken;
  Stream<MensajePush> get enPrimerPlano;
  Stream<MensajePush> get alAbrirDesdeAviso;
  Future<MensajePush?> mensajeQueAbrioLaApp();
  void registrarManejadorSegundoPlano();
}

/// Muestra el aviso cuando la app está abierta y pide el permiso de Android.
abstract interface class PresentadorAvisos {
  Future<void> prepararCanal(String idCanal);
  Future<void> pedirPermiso();
  Future<void> mostrar(MensajePush mensaje);
  Future<String?> rutaPendiente();
}

typedef RegistradorTokenPush = Future<void> Function(String token);

/// Enlaza permiso, canal, token y el toque que abre la cápsula.
class SesionAvisosPush {
  SesionAvisosPush({
    required this.fuente,
    required this.presentador,
    required this.alRegistrarToken,
    required this.alAbrirRuta,
    required this.esAndroid,
    required this.esIos,
    required this.sdkAndroid,
    this.alRecibirEnPrimerPlano,
  });

  final FuenteMensajesPush fuente;
  final PresentadorAvisos presentador;
  final RegistradorTokenPush alRegistrarToken;
  final void Function(String ruta) alAbrirRuta;
  final bool esAndroid;
  final bool esIos;
  final int sdkAndroid;

  /// Se llama con cada aviso que llega con la app abierta (Android e iOS),
  /// para refrescar datos aunque el aviso solo se muestre en Android.
  final void Function(MensajePush mensaje)? alRecibirEnPrimerPlano;

  final List<StreamSubscription<dynamic>> _suscripciones = [];

  Future<void> iniciar() async {
    if (!esAndroid && !esIos) return;
    try {
      if (esAndroid) {
        await presentador.prepararCanal(CanalAvisos.id);
        if (CanalAvisos.debePedirPermiso(sdkAndroid)) {
          await presentador.pedirPermiso();
        }
      }
      if (esIos) {
        await fuente.presentarEnPrimerPlanoIos();
        await fuente.pedirPermisoIos();
      }
    } catch (error, traza) {
      debugPrint('Capsoul: permiso de avisos: $error');
      debugPrintStack(stackTrace: traza);
    }

    fuente.registrarManejadorSegundoPlano();
    _suscripciones.add(fuente.renovacionesToken.listen(_publicarToken));
    _suscripciones.add(fuente.enPrimerPlano.listen(_mostrarEnPrimerPlano));
    _suscripciones.add(fuente.alAbrirDesdeAviso.listen(_abrir));

    try {
      await _publicarToken(await fuente.tokenActual());
      final inicial = await fuente.mensajeQueAbrioLaApp();
      if (inicial != null) _abrir(inicial);
      if (esAndroid) {
        final pendiente = await presentador.rutaPendiente();
        if (pendiente != null && pendiente.isNotEmpty) alAbrirRuta(pendiente);
      }
    } catch (error, traza) {
      debugPrint('Capsoul: no se pudo enlazar FCM: $error');
      debugPrintStack(stackTrace: traza);
    }
  }

  Future<void> _publicarToken(String? token) async {
    if (token == null || token.isEmpty) return;
    try {
      await alRegistrarToken(token);
    } catch (error, traza) {
      debugPrint('Capsoul: no se pudo registrar el token push: $error');
      debugPrintStack(stackTrace: traza);
    }
  }

  Future<void> _mostrarEnPrimerPlano(MensajePush mensaje) async {
    try {
      alRecibirEnPrimerPlano?.call(mensaje);
    } catch (error, traza) {
      debugPrint('Capsoul: no se procesó el aviso en primer plano: $error');
      debugPrintStack(stackTrace: traza);
    }
    if (!esAndroid) return;
    try {
      await presentador.mostrar(mensaje);
    } catch (error, traza) {
      debugPrint('Capsoul: no se mostró el aviso: $error');
      debugPrintStack(stackTrace: traza);
    }
  }

  void _abrir(MensajePush mensaje) {
    final ruta = mensaje.ruta;
    if (ruta == null || ruta.isEmpty) return;
    alAbrirRuta(ruta);
  }

  void cerrar() {
    for (final suscripcion in _suscripciones) {
      unawaited(suscripcion.cancel());
    }
    _suscripciones.clear();
  }
}
