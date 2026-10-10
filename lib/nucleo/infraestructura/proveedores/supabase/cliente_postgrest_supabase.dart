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
      protegerPostgrest(
        () => _cliente.rpc<List<dynamic>>(nombre, params: parametros),
      );
}
