import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_capsoul.dart';
import 'nucleo/firebase/app_error_arranque.dart';
import 'nucleo/firebase/arranque_firebase.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final firebaseListo = await inicializarFirebase();
  if (!firebaseListo) {
    runApp(const AppErrorArranque());
    return;
  }
  runApp(const ProviderScope(child: AppCapsoul()));
}
