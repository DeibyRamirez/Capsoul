import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'configuracion_supabase.dart';

/// Inicializa Supabase (Auth + Postgres) con la configuración de
/// `--dart-define`.
///
/// Devuelve `null` cuando Supabase está listo, o un mensaje en español para
/// la pantalla de error de arranque. Nunca lanza.
Future<String?> inicializarSupabase() async {
  final problema = problemaConfiguracionSupabase(
    url: ConfiguracionSupabase.url,
    claveAnonima: ConfiguracionSupabase.claveAnonima,
  );
  if (problema != null) {
    debugPrint('Capsoul: $problema');
    return problema;
  }
  try {
    await Supabase.initialize(
      url: ConfiguracionSupabase.url.trim(),
      publishableKey: ConfiguracionSupabase.claveAnonima.trim(),
    );
    return null;
  } catch (error, trazaPila) {
    debugPrint('Capsoul: no se pudo inicializar Supabase: $error');
    debugPrintStack(stackTrace: trazaPila);
    return 'No pudimos conectar con el servidor de Capsoul.';
  }
}
