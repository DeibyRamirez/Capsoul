import 'package:capsoul/funcionalidades/amistades/dominio/amigo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Amigo.desdeFilaRpc mapea foto_public_id', () {
    final amigo = Amigo.desdeFilaRpc({
      'usuario_id': 'u1',
      'nombre_visible': 'Ana',
      'nombre_usuario': 'ana',
      'foto_public_id': 'capsoul/usuarios/u1/avatar',
    });
    expect(amigo?.fotoPublicId, 'capsoul/usuarios/u1/avatar');
    expect(amigo?.tieneFoto, isTrue);
  });
}
