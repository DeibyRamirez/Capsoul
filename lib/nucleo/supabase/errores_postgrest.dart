/// Utilidades para leer los errores de PostgREST/Postgres.
abstract final class ErroresPostgrest {
  /// SQLSTATE de permiso denegado (RLS o GRANT).
  static const String permisoDenegado = '42501';

  /// Errores de JWT de PostgREST (token ausente, vencido o inválido).
  static const Set<String> sesionInvalida = {'PGRST301', 'PGRST302', 'PGRST303'};

  static final RegExp _tablaRls =
      RegExp(r'row-level security policy for table "([a-z_]+)"');

  /// Tabla que rechazó la fila por RLS (`new row violates row-level security
  /// policy for table "x"`), o `null` si el mensaje no la nombra.
  static String? tablaDeViolacionRls(String mensaje) =>
      _tablaRls.firstMatch(mensaje)?.group(1);
}
