import 'package:supabase_flutter/supabase_flutter.dart';

/// Capa mínima sobre PostgREST para `capsulas`, `elementos` y
/// `capsula_elementos` (existe para simular la base en pruebas sin imitar
/// los builders encadenados de `supabase_flutter`).
abstract interface class AccesoTablasCapsulas {
  /// Inserta una fila en `elementos` y devuelve su id.
  Future<String> insertarElemento(Map<String, dynamic> fila);

  /// Inserta una fila en `capsulas` y devuelve su id.
  Future<String> insertarCapsula(Map<String, dynamic> fila);

  Future<void> insertarEnlaces(List<Map<String, dynamic>> filas);

  Future<void> actualizarEstadoCapsula(String id, String estado);

  Future<void> eliminarCapsula(String id);

  Future<void> eliminarElementos(List<String> ids);

  Future<List<Map<String, dynamic>>> leerCapsulasDeAutor(String autorId);

  Future<Map<String, dynamic>?> leerCapsulaConElementos(String id);
}

class AccesoTablasCapsulasSupabase implements AccesoTablasCapsulas {
  AccesoTablasCapsulasSupabase({SupabaseClient? cliente})
      : _clienteInyectado = cliente;

  static const String columnasCapsula =
      'id, autor_id, titulo, mensaje, fecha_apertura, estado, liberada_en, '
      'creado_en';

  static const String columnasConElementos = '$columnasCapsula, '
      'capsula_elementos(orden, elementos(id, tipo, contenido_texto, '
      'cloudinary_public_id, bytes, duracion_segundos))';

  static const int limiteLista = 50;

  final SupabaseClient? _clienteInyectado;

  SupabaseClient get _cliente => _clienteInyectado ?? Supabase.instance.client;

  @override
  Future<String> insertarElemento(Map<String, dynamic> fila) async {
    final insertada =
        await _cliente.from('elementos').insert(fila).select('id').single();
    return insertada['id'] as String;
  }

  @override
  Future<String> insertarCapsula(Map<String, dynamic> fila) async {
    final insertada =
        await _cliente.from('capsulas').insert(fila).select('id').single();
    return insertada['id'] as String;
  }

  @override
  Future<void> insertarEnlaces(List<Map<String, dynamic>> filas) async {
    if (filas.isEmpty) return;
    await _cliente.from('capsula_elementos').insert(filas);
  }

  @override
  Future<void> actualizarEstadoCapsula(String id, String estado) async {
    await _cliente.from('capsulas').update({'estado': estado}).eq('id', id);
  }

  @override
  Future<void> eliminarCapsula(String id) async {
    await _cliente.from('capsulas').delete().eq('id', id);
  }

  @override
  Future<void> eliminarElementos(List<String> ids) async {
    if (ids.isEmpty) return;
    await _cliente.from('elementos').delete().inFilter('id', ids);
  }

  @override
  Future<List<Map<String, dynamic>>> leerCapsulasDeAutor(String autorId) {
    return _cliente
        .from('capsulas')
        .select(columnasCapsula)
        .eq('autor_id', autorId)
        .neq('estado', 'cancelada')
        .order('creado_en', ascending: false)
        .limit(limiteLista);
  }

  @override
  Future<Map<String, dynamic>?> leerCapsulaConElementos(String id) {
    return _cliente
        .from('capsulas')
        .select(columnasConElementos)
        .eq('id', id)
        .maybeSingle();
  }
}
