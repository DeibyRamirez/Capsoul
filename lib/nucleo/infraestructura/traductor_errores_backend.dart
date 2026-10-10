/// Utilidades para leer errores de PostgREST/Postgres de forma agnóstica al
/// proveedor.
abstract final class TraductorErroresBackend {
  /// SQLSTATE de permiso denegado (RLS o GRANT).
  static const String permisoDenegado = '42501';

  /// Errores de JWT de PostgREST (token ausente, vencido o inválido).
  static const Set<String> sesionInvalida = {'PGRST301', 'PGRST302', 'PGRST303'};

  static final RegExp _tablaRls =
      RegExp(r'row-level security policy for table "([a-z_]+)"');

  /// Tabla que rechazó la fila por RLS, o `null` si el mensaje no la nombra.
  static String? tablaDeViolacionRls(String mensaje) =>
      _tablaRls.firstMatch(mensaje)?.group(1);
}

/// Error de PostgREST independiente del SDK de Supabase.
class ErrorPostgrest implements Exception {
  const ErrorPostgrest({this.codigo, required this.mensaje});

  final String? codigo;
  final String mensaje;

  @override
  String toString() => 'ErrorPostgrest($codigo): $mensaje';
}
