import 'package:supabase_flutter/supabase_flutter.dart';

/// Capa mínima sobre PostgREST para la tabla `usuarios`. Existe para poder
/// simular la base de datos en las pruebas sin imitar los builders
/// encadenados de `supabase_flutter`.
abstract interface class AccesoTablaUsuarios {
  /// Devuelve la fila de [id] o `null` si no existe o RLS la oculta.
  Future<Map<String, dynamic>?> leerFila(String id);

  /// Actualiza `nombre_visible` y devuelve cuántas filas cambiaron (0 si la
  /// fila no existe o RLS no la deja editar).
  Future<int> actualizarNombreVisible(String id, String nombreVisible);
}

/// [AccesoTablaUsuarios] contra Supabase. Respeta los GRANT por columna de la
/// migración: el cliente solo puede editar `nombre_visible`,
/// `foto_public_id` y `perfil_publico` de su propia fila.
class AccesoTablaUsuariosSupabase implements AccesoTablaUsuarios {
  AccesoTablaUsuariosSupabase({SupabaseClient? cliente})
      : _clienteInyectado = cliente;

  static const String tabla = 'usuarios';

  static const String columnas =
      'id, nombre_visible, correo, foto_public_id, perfil_publico, creado_en';

  final SupabaseClient? _clienteInyectado;

  SupabaseClient get _cliente => _clienteInyectado ?? Supabase.instance.client;

  @override
  Future<Map<String, dynamic>?> leerFila(String id) {
    return _cliente.from(tabla).select(columnas).eq('id', id).maybeSingle();
  }

  @override
  Future<int> actualizarNombreVisible(String id, String nombreVisible) async {
    final filas = await _cliente
        .from(tabla)
        .update({'nombre_visible': nombreVisible})
        .eq('id', id)
        .select('id');
    return filas.length;
  }
}
