import 'consulta_postgrest.dart';

/// Cliente agnóstico para leer y escribir en Postgres vía PostgREST.
abstract interface class ClientePostgrest {
  TablaPostgrest from(String tabla);

  Future<List<dynamic>> rpc(
    String nombre, {
    Map<String, dynamic>? parametros,
  });
}
