import 'package:flutter/foundation.dart';

/// Sprint 1 Firebase bootstrap.
///
/// When [lib/firebase_options.dart] is missing (flutterfire configure pending),
/// initialization is skipped safely so the app still runs.
Future<void> bootstrapFirebase() async {
  // Do not invent fake project IDs. Wait for flutterfire configure.
  debugPrint(
    'Capsoul: Firebase init diferido \u2014 ejecuta flutterfire configure '
    'para generar lib/firebase_options.dart',
  );
}