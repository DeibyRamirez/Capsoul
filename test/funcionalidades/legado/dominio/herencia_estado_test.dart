import 'package:capsoul/funcionalidades/legado/dominio/condicion_herencia.dart';
import 'package:capsoul/funcionalidades/legado/dominio/estado_herencia.dart';
import 'package:capsoul/funcionalidades/legado/dominio/herencia.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Herencia h({
    EstadoHerencia estado = EstadoHerencia.activa,
    CondicionHerencia condicion = CondicionHerencia.fecha,
    DateTime? fecha,
  }) {
    return Herencia(
      id: 'h1',
      titulo: 'Reloj',
      estado: estado,
      condicionActivacion: condicion,
      fechaActivacion: fecha,
      propietarioId: 'u1',
      beneficiarioUsuarioId: 'u3',
    );
  }

  final ahora = DateTime(2026, 11, 2);

  test('sellada por fecha se puede editar antes del día', () {
    final herencia = h(fecha: DateTime(2026, 12, 1));
    expect(herencia.sePuedeEditar(ahora: ahora), isTrue);
    expect(herencia.etiquetaEstado(ahora: ahora), 'Asignada · espera la fecha');
  });

  test('liberada no se edita', () {
    final herencia = h(
      estado: EstadoHerencia.liberada,
      fecha: DateTime(2026, 12, 1),
    );
    expect(herencia.sePuedeEditar(ahora: ahora), isFalse);
    expect(herencia.etiquetaEstado(ahora: ahora), 'Liberada');
  });

  test('fecha ya vencida no se edita', () {
    final herencia = h(fecha: DateTime(2026, 10, 1));
    expect(herencia.sePuedeEditar(ahora: ahora), isFalse);
  });
}
