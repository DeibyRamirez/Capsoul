import 'package:capsoul/funcionalidades/capsulas/dominio/capsula_recibida.dart';
import 'package:capsoul/funcionalidades/capsulas/dominio/estado_capsula.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('titulo oculto si no está liberada', () {
    final recibida = CapsulaRecibida.desdeFilaRpc({
      'capsula_id': 'c1',
      'autor_id': 'a1',
      'autor_nombre': 'Ana',
      'fecha_apertura': '2026-12-01T08:00:00Z',
      'estado': 'programada',
      'titulo': 'Secreto',
    });
    expect(recibida, isNotNull);
    expect(recibida!.tituloVisible, 'Cápsula para ti');
    expect(recibida.estaLiberada, false);
  });

  test('titulo visible si está liberada', () {
    final recibida = CapsulaRecibida.desdeFilaRpc({
      'capsula_id': 'c1',
      'autor_id': 'a1',
      'autor_nombre': 'Ana',
      'fecha_apertura': '2026-01-01T08:00:00Z',
      'estado': EstadoCapsula.liberada.valorBd,
      'titulo': 'Hola',
      'liberada_en': '2026-01-01T08:05:00Z',
    });
    expect(recibida!.tituloVisible, 'Hola');
  });
}
