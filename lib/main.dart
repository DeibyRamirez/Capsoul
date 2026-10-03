import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_capsoul.dart';
import 'nucleo/arranque/app_error_arranque.dart';
import 'nucleo/firebase/arranque_firebase.dart';
import 'nucleo/supabase/arranque_supabase.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final firebaseListo = await inicializarFirebase();
  if (!firebaseListo) {
    debugPrint('Capsoul: sigue sin Firebase (sin notificaciones push).');
  }
  final problemaSupabase = await inicializarSupabase();
  if (problemaSupabase != null) {
    runApp(AppErrorArranque(detalle: problemaSupabase));
    return;
  }
  runApp(const ProviderScope(child: AppCapsoul()));
}
