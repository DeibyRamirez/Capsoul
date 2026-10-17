import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../configuracion_backend.dart';
import 'almacenamiento_sesion_auth.dart';
import 'migracion_sesion_shared_preferences.dart';

/// Inicializa Supabase (Auth + Postgres) con la configuración de
/// `--dart-define`.
Future<String?> inicializarSupabaseBackend() async {
  final problema = problemaConfiguracionBackend(
    backend: ConfiguracionBackend.backend,
    postgrestUrl: ConfiguracionBackend.postgrestUrl,
    clavePublica: ConfiguracionBackend.clavePublica,
    apiBaseUrl: ConfiguracionBackend.apiBaseUrl,
  );
  if (problema != null) {
    debugPrint('Capsoul: $problema');
    return problema;
  }
  try {
    LocalStorage? almacenamientoSesion;
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      final seguro = AlmacenamientoSesionAuth();
      await migrarSesionDesdeSharedPreferencesSiHaceFalta(destino: seguro);
      almacenamientoSesion = seguro;
    }
    await Supabase.initialize(
      url: ConfiguracionBackend.postgrestUrl.trim(),
      publishableKey: ConfiguracionBackend.clavePublica.trim(),
      authOptions: almacenamientoSesion != null
          ? FlutterAuthClientOptions(localStorage: almacenamientoSesion)
          : const FlutterAuthClientOptions(),
    );
    return null;
  } catch (error, trazaPila) {
    debugPrint('Capsoul: no se pudo inicializar Supabase: $error');
    debugPrintStack(stackTrace: trazaPila);
    return 'No pudimos conectar con el servidor de Capsoul.';
  }
}
