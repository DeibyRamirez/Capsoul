import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'aviso_push.dart';
import 'canal_avisos.dart';
import 'coordinador_avisos_push.dart';

/// Canal nativo `capsoul/avisos`: permiso, canal de alta importancia y bandeja.
class PresentadorAvisosAndroid implements PresentadorAvisos {
  PresentadorAvisosAndroid({MethodChannel? canal})
      : _canal = canal ?? const MethodChannel(CanalAvisos.metodo);

  final MethodChannel _canal;

  bool get _enAndroid => !kIsWeb && Platform.isAndroid;

  @override
  Future<void> prepararCanal(String idCanal) async {
    if (!_enAndroid) return;
    await _canal.invokeMethod<void>('prepararCanal', {'id': idCanal});
  }

  @override
  Future<void> pedirPermiso() async {
    if (!_enAndroid) return;
    await _canal.invokeMethod<void>('pedirPermiso');
  }

  @override
  Future<void> mostrar(MensajePush mensaje) async {
    if (!_enAndroid) return;
    await _canal.invokeMethod<void>('mostrar', {
      'titulo': mensaje.titulo ?? 'Capsoul',
      'cuerpo': mensaje.cuerpo ?? '',
      'ruta': mensaje.ruta,
    });
  }

  @override
  Future<String?> rutaPendiente() async {
    if (!_enAndroid) return null;
    final ruta = await _canal.invokeMethod<String>('rutaPendiente');
    if (ruta == null || ruta.isEmpty) return null;
    return ruta;
  }

  Future<int> leerSdk() async {
    if (!_enAndroid) return 0;
    return await _canal.invokeMethod<int>('sdk') ?? 0;
  }

  void escucharToques(void Function(String ruta) alAbrir) {
    if (!_enAndroid) return;
    _canal.setMethodCallHandler((llamada) async {
      if (llamada.method == 'abrirRuta' && llamada.arguments is String) {
        final ruta = llamada.arguments as String;
        if (ruta.isNotEmpty) alAbrir(ruta);
      }
    });
  }
}
