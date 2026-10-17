import '../infraestructura/proveedores/supabase/arranque_supabase.dart'
    as infra;

/// Compatibilidad con imports antiguos. Usar [inicializarBackend] en su lugar.
Future<String?> inicializarSupabase() => infra.inicializarSupabaseBackend();
