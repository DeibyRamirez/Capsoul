import 'package:flutter/foundation.dart';

import '../dominio/repositorio_resumen_inicio.dart';
import '../dominio/resumen_inicio.dart';
import 'acceso_tablas_resumen_inicio.dart';

class RepositorioResumenInicioSupabase implements RepositorioResumenInicio {
  RepositorioResumenInicioSupabase(this._acceso);

  final AccesoTablasResumenInicio _acceso;

  @override
  Future<ResumenInicio> leerResumen(String uid) async {
    final conteos = await Future.wait([
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
      return await _acceso.contar(
        tabla,
        iguales: iguales,
        distintos: distintos,
      );
    } catch (error) {
      debugPrint('Capsoul: no se pudo contar $tabla: $error');
      return 0;
    }
  }
}
