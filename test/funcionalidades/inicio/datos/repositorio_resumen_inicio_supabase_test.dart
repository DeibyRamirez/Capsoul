import 'package:capsoul/funcionalidades/inicio/datos/repositorio_resumen_inicio_supabase.dart';
import 'package:capsoul/funcionalidades/inicio/dominio/resumen_inicio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cuenta cada sección con sus filtros y deja en 0 la que falla', () async {
    final consultas = <String, (Map<String, String>, Map<String, String>)>{};
    final repositorio = RepositorioResumenInicioSupabase(
      contador: (tabla, {required iguales, distintos = const {}}) async {
        consultas[tabla] = (iguales, distintos);
        return switch (tabla) {
          'momentos' => 128,
          'reto_participantes' => throw Exception('sin tabla'),
          'capsulas' => 5,
          'herencias' => 2,
          _ => 0,
        };
      },
    );

    final resumen = await repositorio.leerResumen('uid-1');

    expect(
      resumen,
      const ResumenInicio(recuerdos: 128, retosActivos: 0, capsulas: 5, herencias: 2),
    );
    expect(consultas['capsulas']?.$1, {'autor_id': 'uid-1'});
    expect(consultas['capsulas']?.$2, {'estado': 'cancelada'});
    expect(consultas['reto_participantes']?.$1, {
      'usuario_id': 'uid-1',
      'estado': 'aceptado',
    });
    expect(consultas['herencias']?.$2, {'estado': 'revocada'});
  });
}
