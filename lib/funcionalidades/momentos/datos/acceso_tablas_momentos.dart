import 'package:supabase_flutter/supabase_flutter.dart';

import '../../recuerdos/datos/mapeo_recuerdos.dart';

/// Capa mínima sobre PostgREST para `momentos` y `momento_elementos` (se
/// simula en pruebas).
abstract interface class AccesoTablasMomentos {
  /// Inserta el momento (ya trae su `id`; sin RETURNING).
  Future<void> insertarMomento(Map<String, dynamic> fila);

  Future<void> insertarEnlaces(List<Map<String, dynamic>> filas);

  Future<void> actualizarPortada(String id, String? elementoId);

  /// Devuelve cuántas filas se borraron (0 si RLS lo impidió).
  Future<int> eliminarMomento(String id);

  Future<List<Map<String, dynamic>>> listarDeAutor(String autorId);

  Future<Map<String, dynamic>?> leerConRecuerdos(String id);
}

class AccesoTablasMomentosSupabase implements AccesoTablasMomentos {
  AccesoTablasMomentosSupabase({SupabaseClient? cliente})
      : _clienteInyectado = cliente;

  static const String columnasMomento =
      'id, autor_id, titulo, texto, creado_en, '
      'portada:elementos!momentos_portada_elemento_id_fkey($columnasRecuerdo)';

  static const String columnasListado =
      '$columnasMomento, momento_elementos(count)';

  static const String columnasDetalle =
      '$columnasMomento, momento_elementos(orden, elementos($columnasRecuerdo))';

  static const int limiteLista = 100;

  final SupabaseClient? _clienteInyectado;

  SupabaseClient get _cliente => _clienteInyectado ?? Supabase.instance.client;

  @override
  Future<void> insertarMomento(Map<String, dynamic> fila) async {
    await _cliente.from('momentos').insert(fila);
  }

  @override
  Future<void> insertarEnlaces(List<Map<String, dynamic>> filas) async {
    if (filas.isEmpty) return;
    await _cliente.from('momento_elementos').insert(filas);
  }

  @override
  Future<void> actualizarPortada(String id, String? elementoId) async {
    await _cliente
        .from('momentos')
        .update({'portada_elemento_id': elementoId}).eq('id', id);
  }

  @override
  Future<int> eliminarMomento(String id) async {
    final borradas =
        await _cliente.from('momentos').delete().eq('id', id).select('id');
    return borradas.length;
  }

  @override
  Future<List<Map<String, dynamic>>> listarDeAutor(String autorId) {
    return _cliente
        .from('momentos')
        .select(columnasListado)
        .eq('autor_id', autorId)
        .order('creado_en', ascending: false)
        .limit(limiteLista);
  }

  @override
  Future<Map<String, dynamic>?> leerConRecuerdos(String id) {
    return _cliente
        .from('momentos')
        .select(columnasDetalle)
        .eq('id', id)
        .maybeSingle();
  }
}
