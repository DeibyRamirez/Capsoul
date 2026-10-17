import 'package:capsoul/funcionalidades/legado/dominio/grupo_legado_beneficiario.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('etiquetaPara usa nombre visible', () {
    const g = GrupoLegadoBeneficiario(
      beneficiarioUsuarioId: 'u1',
      nombreVisible: 'Jacobo',
      nHerencias: 2,
      nCapsulas: 1,
    );
    expect(g.etiquetaPara(), 'Para Jacobo');
  });

  test('ResumenLegado desde json', () {
    final r = ResumenLegado.desdeJson({
      'herencias_activas': 3,
      'tiene_instrucciones': true,
    });
    expect(r.herenciasActivas, 3);
    expect(r.tieneInstrucciones, isTrue);
  });
}
