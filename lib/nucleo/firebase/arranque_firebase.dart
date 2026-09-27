import 'package:capsoul/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Inicializa Firebase (proyecto `capsoul-ebea3`) con las opciones generadas
/// por `flutterfire configure`.
///
/// Devuelve `true` cuando Firebase está listo. Los errores se registran en
/// lugar de lanzarse para que `main` pueda mostrar una pantalla de error
/// amigable.
Future<bool> inicializarFirebase() async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    return true;
  } catch (error, trazaPila) {
    debugPrint('Capsoul: no se pudo inicializar Firebase: $error');
    debugPrintStack(stackTrace: trazaPila);
    return false;
  }
}
