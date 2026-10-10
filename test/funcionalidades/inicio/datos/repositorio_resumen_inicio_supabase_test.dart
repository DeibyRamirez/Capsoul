import 'package:capsoul/funcionalidades/inicio/datos/acceso_tablas_resumen_inicio.dart';
import 'package:capsoul/funcionalidades/inicio/datos/repositorio_resumen_inicio_supabase.dart';
import 'package:capsoul/funcionalidades/inicio/dominio/resumen_inicio.dart';
import 'package:flutter_test/flutter_test.dart';

class _AccesoFalso implements AccesoTablasResumenInicio {
  final Future<int> Function(
    String tabla, {
    required Map<String, String> iguales,
    Map<String, String> distintos,
  }) contador;

  _AccesoFalso(this.contador);

  @override
  Future<int> contar(
    String tabla, {
    required Map<String, String> iguales,
    Map<String, String> distintos = const {},
  }) =>
      contador(tabla, iguales: iguales, distintos: distintos);
}

void main() {
  test('cuenta cada sección con sus filtros y deja en 0 la que falla', () async {
    final consultas = <String, (Map<String, String>, Map<String, String>)>{};
    final repositorio = RepositorioResumenInicioSupabase(
      _AccesoFalso((tabla, {required iguales, distintos = const {}}) async {
        consultas[tabla] = (iguales, distintos);
        return switch (tabla) {
          'elementos' => 128,
          'reto_participantes' => throw Exception('sin tabla'),
          'capsulas' => 5,
          'herencias' => 2,
          _ => 0,
        };
      }),
    );

    final resumen = await repositorio.leerResumen('uid-1');

    expect(
      resumen,
      const ResumenInicio(
        recuerdos: 128,
        retosActivos: 0,
        capsulas: 5,
        herencias: 2,
      ),
    );
    expect(consultas['elementos']?.$1, {'propietario_id': 'uid-1'});
    expect(consultas['capsulas']?.$1, {'autor_id': 'uid-1'});
    expect(consultas['capsulas']?.$2, {'estado': 'cancelada'});
    expect(consultas['reto_participantes']?.$1, {
      'usuario_id': 'uid-1',
      'estado': 'aceptado',
    });
    expect(consultas['herencias']?.$2, {'estado': 'revocada'});
  });
}
