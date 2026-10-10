import 'package:flutter/foundation.dart';

import 'configuracion_backend.dart';
import 'proveedores/supabase/arranque_supabase.dart';

/// Inicializa el backend según [ConfiguracionBackend.backend].
///
/// Devuelve `null` cuando está listo, o un mensaje en español para la pantalla
/// de error de arranque.
Future<String?> inicializarBackend() async {
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
  if (ConfiguracionBackend.esSupabase) {
    return inicializarSupabaseBackend();
  }
  // En modo VPS no hay SDK que inicializar: los clientes HTTP se crean bajo
  // demanda con el JWT de la sesión.
  return null;
}
