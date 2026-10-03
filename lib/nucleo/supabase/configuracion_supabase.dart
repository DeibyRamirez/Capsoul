/// Configuración de Supabase inyectada en compilación con `--dart-define`
/// o `--dart-define-from-file=env/dev.json`. Nunca se escriben claves en el
/// repositorio (ver `env/dev.json.example`).
abstract final class ConfiguracionSupabase {
  /// URL del proyecto, p. ej. `https://<ref>.supabase.co`.
  static const String url = String.fromEnvironment('SUPABASE_URL');

  /// Clave pública del cliente (anon key o publishable key). Nunca la
  /// `service_role` ni una clave secreta.
  static const String claveAnonima = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Deep link al que vuelve el enlace de confirmación de correo. Debe estar
  /// en las *Redirect URLs* de Supabase Auth y en AndroidManifest/Info.plist.
  static const String urlConfirmacion = 'capsoul://auth/confirmar';

  /// Deep link al que vuelve el enlace de recuperación de contraseña.
  static const String urlRecuperacion = 'capsoul://auth/recuperar';
}

/// Devuelve un mensaje en español si la configuración no sirve para
/// arrancar, o `null` si está completa.
String? problemaConfiguracionSupabase({
  required String url,
  required String claveAnonima,
}) {
  final faltantes = <String>[
    if (url.trim().isEmpty) 'SUPABASE_URL',
    if (claveAnonima.trim().isEmpty) 'SUPABASE_ANON_KEY',
  ];
  if (faltantes.isNotEmpty) {
    return 'Falta la configuración del servidor (${faltantes.join(' y ')}). '
        'Compila con --dart-define-from-file=env/dev.json.';
  }
  final uri = Uri.tryParse(url.trim());
  if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
    return 'SUPABASE_URL no es una dirección https válida.';
  }
  return null;
}
