import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../configuracion_backend.dart';

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
    await Supabase.initialize(
      url: ConfiguracionBackend.postgrestUrl.trim(),
      publishableKey: ConfiguracionBackend.clavePublica.trim(),
    );
    return null;
  } catch (error, trazaPila) {
    debugPrint('Capsoul: no se pudo inicializar Supabase: $error');
    debugPrintStack(stackTrace: trazaPila);
    return 'No pudimos conectar con el servidor de Capsoul.';
  }
}
