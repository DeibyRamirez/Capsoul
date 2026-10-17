import 'package:supabase_flutter/supabase_flutter.dart';

import '../../cliente_postgrest.dart';
import '../../consulta_postgrest.dart';
import 'consulta_postgrest_supabase.dart';

/// [ClientePostgrest] respaldado por el SDK de Supabase.
class ClientePostgrestSupabase implements ClientePostgrest {
  ClientePostgrestSupabase({SupabaseClient? cliente})
      : _cliente = cliente ?? Supabase.instance.client;

  final SupabaseClient _cliente;

  @override
  TablaPostgrest from(String tabla) =>
      TablaPostgrestSupabase(_cliente.from(tabla));

  @override
  Future<List<dynamic>> rpc(
    String nombre, {
    Map<String, dynamic>? parametros,
  }) =>
      protegerPostgrest(() async {
        final datos = await _cliente.rpc<dynamic>(
          nombre,
          params: parametros,
        );
        return respuestaRpcComoLista(datos);
      });
}

/// PostgREST devuelve listas para `RETURNS TABLE` y escalares para `RETURNS int`, etc.
List<dynamic> respuestaRpcComoLista(dynamic datos) {
  if (datos is List) return datos;
  if (datos == null) return const [];
  return [datos];
}
