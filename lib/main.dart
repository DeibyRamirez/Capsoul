import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_capsoul.dart';
import 'nucleo/arranque/app_error_arranque.dart';
import 'nucleo/firebase/arranque_firebase.dart';
import 'nucleo/firebase/servicio_notificaciones_push.dart';
import 'nucleo/infraestructura/arranque_backend.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final firebaseListo = await inicializarFirebase();
  if (firebaseListo) {
    await inicializarNotificacionesPush();
  } else {
    debugPrint('Capsoul: sigue sin Firebase (sin notificaciones push).');
  }

  final problemaBackend = await inicializarBackend();
  if (problemaBackend != null) {
    runApp(AppErrorArranque(detalle: problemaBackend));
    return;
  }
  runApp(const ProviderScope(child: AppCapsoul()));
}
