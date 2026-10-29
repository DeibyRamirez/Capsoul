import 'package:capsoul/funcionalidades/capsulas/dominio/avisos_capsulas.dart';
import 'package:capsoul/funcionalidades/capsulas/dominio/capsula_recibida.dart';
import 'package:capsoul/funcionalidades/capsulas/dominio/estado_capsula.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  CapsulaRecibida recibida({
    required String id,
    required String autorId,
    required EstadoCapsula estado,
    DateTime? liberadaEn,
    DateTime? leidaEn,
  }) {
    return CapsulaRecibida(
      id: id,
      autorId: autorId,
      autorNombre: 'Beto',
      titulo: id,
      fechaApertura: DateTime.utc(2026, 10, 1),
      estado: estado,
      liberadaEn: liberadaEn,
      leidaEn: leidaEn,
    );
  }

  test('el badge ignora las propias, las cerradas y las ya leídas', () {
    final avisos = avisosCapsulasCompartidas([
      recibida(
        id: 'propia',
        autorId: 'yo',
        estado: EstadoCapsula.liberada,
        liberadaEn: DateTime.utc(2026, 10, 3),
      ),
      recibida(
        id: 'cerrada',
        autorId: 'otro',
        estado: EstadoCapsula.programada,
      ),
      recibida(
        id: 'leida',
        autorId: 'otro',
        estado: EstadoCapsula.liberada,
        liberadaEn: DateTime.utc(2026, 10, 2),
        leidaEn: DateTime.utc(2026, 10, 4),
      ),
      recibida(
        id: 'nueva',
        autorId: 'otro',
        estado: EstadoCapsula.liberada,
        liberadaEn: DateTime.utc(2026, 10, 1),
      ),
      recibida(
        id: 'mas-nueva',
        autorId: 'otro',
        estado: EstadoCapsula.liberada,
        liberadaEn: DateTime.utc(2026, 10, 5),
      ),
    ], 'yo');

    expect(avisos.map((aviso) => aviso.id), ['mas-nueva', 'leida', 'nueva']);
    expect(conteoAvisosSinLeer(avisos), 2);
    expect(textoBadgeAvisos(0), isNull);
    expect(textoBadgeAvisos(2), '2');
    expect(textoBadgeAvisos(9), '9');
    expect(textoBadgeAvisos(10), '9+');
  });
}
