import 'package:supabase_flutter/supabase_flutter.dart';

import 'mapeo_recuerdos.dart';

/// Capa mínima sobre PostgREST para `elementos` (se simula en pruebas).
abstract interface class AccesoTablasRecuerdos {
  /// Inserta una fila (ya trae su `id`; sin RETURNING).
  Future<void> insertar(Map<String, dynamic> fila);

  Future<List<Map<String, dynamic>>> listar({
    required String propietarioId,
    List<String> tipos = const [],
    String? desde,
    String? hasta,
    int limite = 200,
  });

  Future<Map<String, dynamic>?> leerPorId(String id);

  /// Cápsulas programadas o liberadas que contienen el elemento.
  Future<int> contarCapsulasSelladas(String id);

  /// Devuelve cuántas filas se borraron (0 si RLS lo impidió).
  Future<int> eliminar(String id);

  /// Fila de `mi_uso_medios()` (`bytes_usados`, `bytes_limite`).
  Future<Map<String, dynamic>?> leerUsoMedios();
}

class AccesoTablasRecuerdosSupabase implements AccesoTablasRecuerdos {
  AccesoTablasRecuerdosSupabase({SupabaseClient? cliente})
      : _clienteInyectado = cliente;

  final SupabaseClient? _clienteInyectado;

  SupabaseClient get _cliente => _clienteInyectado ?? Supabase.instance.client;

  @override
  Future<void> insertar(Map<String, dynamic> fila) async {
    await _cliente.from('elementos').insert(fila);
  }

  @override
  Future<List<Map<String, dynamic>>> listar({
    required String propietarioId,
    List<String> tipos = const [],
    String? desde,
    String? hasta,
    int limite = 200,
  }) {
    var consulta = _cliente
        .from('elementos')
        .select(columnasRecuerdo)
        .eq('propietario_id', propietarioId);
    if (tipos.isNotEmpty) consulta = consulta.inFilter('tipo', tipos);
    if (desde != null) consulta = consulta.gte('fecha_recuerdo', desde);
    if (hasta != null) consulta = consulta.lte('fecha_recuerdo', hasta);
    return consulta
        .order('fecha_recuerdo', ascending: false)
        .order('creado_en', ascending: false)
        .limit(limite);
  }

  @override
  Future<Map<String, dynamic>?> leerPorId(String id) {
    return _cliente
        .from('elementos')
        .select(columnasRecuerdo)
        .eq('id', id)
        .maybeSingle();
  }

  @override
  Future<int> contarCapsulasSelladas(String id) async {
    final filas = await _cliente
        .from('capsula_elementos')
        .select('capsula_id, capsulas!inner(estado)')
        .eq('elemento_id', id)
        .inFilter('capsulas.estado', const ['programada', 'liberada']);
    return filas.length;
  }

  @override
  Future<int> eliminar(String id) async {
    final borradas =
        await _cliente.from('elementos').delete().eq('id', id).select('id');
    return borradas.length;
  }

  @override
  Future<Map<String, dynamic>?> leerUsoMedios() async {
    final filas = await _cliente.rpc<List<dynamic>>('mi_uso_medios');
    final primera = filas.isEmpty ? null : filas.first;
    return primera is Map<String, dynamic> ? primera : null;
  }
}
