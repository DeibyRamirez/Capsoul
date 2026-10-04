import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../dominio/repositorio_resumen_inicio.dart';
import '../dominio/resumen_inicio.dart';

/// Conteo de filas con filtros de igualdad / desigualdad (adaptador
/// delgado sobre PostgREST para poder simularlo).
typedef ContadorFilas = Future<int> Function(
  String tabla, {
  required Map<String, String> iguales,
  Map<String, String> distintos,
});

/// [RepositorioResumenInicio] con `count=exact` de PostgREST. Cada conteo
/// falla de forma aislada: si uno no se puede leer, vale 0.
class RepositorioResumenInicioSupabase implements RepositorioResumenInicio {
  RepositorioResumenInicioSupabase({ContadorFilas? contador})
      : _contador = contador ?? _contarConSupabase;

  final ContadorFilas _contador;

  @override
  Future<ResumenInicio> leerResumen(String uid) async {
    final conteos = await Future.wait([
      // Recuerdos = banco de recuerdos (filas propias de `elementos`).
      _seguro('elementos', iguales: {'propietario_id': uid}),
      _seguro(
        'reto_participantes',
        iguales: {'usuario_id': uid, 'estado': 'aceptado'},
      ),
      _seguro(
        'capsulas',
        iguales: {'autor_id': uid},
        distintos: {'estado': 'cancelada'},
      ),
      _seguro(
        'herencias',
        iguales: {'propietario_id': uid},
        distintos: {'estado': 'revocada'},
      ),
    ]);
    return ResumenInicio(
      recuerdos: conteos[0],
      retosActivos: conteos[1],
      capsulas: conteos[2],
      herencias: conteos[3],
    );
  }

  Future<int> _seguro(
    String tabla, {
    required Map<String, String> iguales,
    Map<String, String> distintos = const {},
  }) async {
    try {
      return await _contador(tabla, iguales: iguales, distintos: distintos);
    } catch (error) {
      debugPrint('Capsoul: no se pudo contar $tabla: $error');
      return 0;
    }
  }

  static Future<int> _contarConSupabase(
    String tabla, {
    required Map<String, String> iguales,
    Map<String, String> distintos = const {},
  }) async {
    PostgrestFilterBuilder<PostgrestList> consulta =
        Supabase.instance.client.from(tabla).select();
    for (final filtro in iguales.entries) {
      consulta = consulta.eq(filtro.key, filtro.value);
    }
    for (final filtro in distintos.entries) {
      consulta = consulta.neq(filtro.key, filtro.value);
    }
    final respuesta = await consulta.limit(1).count(CountOption.exact);
    return respuesta.count;
  }
}
