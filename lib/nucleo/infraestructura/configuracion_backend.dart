/// Proveedor de backend y URLs inyectadas en compilación con `--dart-define`
/// o `--dart-define-from-file=env/dev.json`.
abstract final class ConfiguracionBackend {
  /// `supabase` (por defecto) o `vps` para PostgREST + API propia.
  static const String backend = String.fromEnvironment(
    'BACKEND',
    defaultValue: 'supabase',
  );

  /// URL de PostgREST. En Supabase coincide con la URL del proyecto.
  static const String postgrestUrl = String.fromEnvironment(
    'POSTGREST_URL',
    defaultValue: String.fromEnvironment('SUPABASE_URL'),
  );

  /// URL base de la API Capsoul (Edge Functions o servidor VPS).
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Clave pública del cliente (anon key de Supabase o equivalente).
  static const String clavePublica = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  /// Deep link al que vuelve el enlace de confirmación de correo.
  static const String urlConfirmacion = 'capsoul://auth/confirmar';

  /// Deep link al que vuelve el enlace de recuperación de contraseña.
  static const String urlRecuperacion = 'capsoul://auth/recuperar';

  static bool get esSupabase => backend != 'vps';
  static bool get esVps => backend == 'vps';
}

/// Devuelve un mensaje en español si la configuración no sirve para
/// arrancar, o `null` si está completa.
String? problemaConfiguracionBackend({
  required String backend,
  required String postgrestUrl,
  required String clavePublica,
  required String apiBaseUrl,
}) {
  if (backend == 'vps') {
    final faltantesVps = <String>[
      if (postgrestUrl.trim().isEmpty) 'POSTGREST_URL',
      if (clavePublica.trim().isEmpty) 'SUPABASE_ANON_KEY',
      if (apiBaseUrl.trim().isEmpty) 'API_BASE_URL',
    ];
    if (faltantesVps.isNotEmpty) {
      return 'Falta la configuración del servidor VPS '
          '(${faltantesVps.join(' y ')}). '
          'Compila con --dart-define-from-file=env/vps.json.';
    }
  } else {
    final faltantes = <String>[
      if (postgrestUrl.trim().isEmpty) 'SUPABASE_URL',
      if (clavePublica.trim().isEmpty) 'SUPABASE_ANON_KEY',
    ];
    if (faltantes.isNotEmpty) {
      return 'Falta la configuración del servidor (${faltantes.join(' y ')}). '
          'Compila con --dart-define-from-file=env/dev.json.';
    }
  }
  final uri = Uri.tryParse(postgrestUrl.trim());
  if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
    return 'La URL de PostgREST no es una dirección https válida.';
  }
  return null;
}
