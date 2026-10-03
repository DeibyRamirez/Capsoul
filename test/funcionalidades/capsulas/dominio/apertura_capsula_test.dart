import 'package:capsoul/funcionalidades/capsulas/dominio/apertura_capsula.dart';
import 'package:capsoul/funcionalidades/capsulas/dominio/capsula.dart';
import 'package:capsoul/funcionalidades/capsulas/dominio/estado_capsula.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final ahora = DateTime(2026, 10, 3, 10);

  Capsula capsula({DateTime? fecha, EstadoCapsula estado = EstadoCapsula.programada}) =>
      Capsula(
        id: 'c1',
        autorId: 'autor',
        titulo: 'Para Jacobo',
        estado: estado,
        creadoEn: DateTime(2026, 8, 13),
        fechaApertura: fecha ?? DateTime(2046, 8, 13, 8),
      );

  group('calcularModoApertura', () {
    test('fecha futura: bloqueada para otros, sellada para el autor', () {
      expect(
        calcularModoApertura(capsula(), uidActual: 'otro', ahora: ahora),
        ModoApertura.bloqueada,
      );
      expect(
        calcularModoApertura(capsula(), uidActual: 'autor', ahora: ahora),
        ModoApertura.selladaParaAutor,
      );
      expect(
        calcularModoApertura(capsula(), uidActual: null, ahora: ahora),
        ModoApertura.bloqueada,
      );
    });

    test('la fecha llegó o el servidor la liberó: lista para abrir', () {
      expect(
        calcularModoApertura(
          capsula(fecha: ahora.subtract(const Duration(minutes: 1))),
          uidActual: 'otro',
          ahora: ahora,
        ),
        ModoApertura.lista,
      );
      expect(
        calcularModoApertura(
          capsula(estado: EstadoCapsula.liberada),
          uidActual: 'otro',
          ahora: ahora,
        ),
        ModoApertura.lista,
      );
    });
  });

  test('formatearFechaCorta usa meses abreviados en español', () {
    expect(formatearFechaCorta(DateTime(2046, 8, 13)), '13 ago 2046');
    expect(formatearFechaCorta(DateTime(2027, 1, 2)), '2 ene 2027');
  });

  group('diferenciaCalendario', () {
    test('cuenta años, meses y días completos', () {
      expect(
        diferenciaCalendario(DateTime(2026, 10, 3), DateTime(2046, 8, 13)),
        (anios: 19, meses: 10, dias: 10),
      );
      expect(
        diferenciaCalendario(DateTime(2026, 1, 31), DateTime(2026, 3, 1)),
        (anios: 0, meses: 1, dias: 1),
      );
    });

    test('es cero si la fecha ya pasó', () {
      expect(
        diferenciaCalendario(DateTime(2026, 10, 3), DateTime(2026, 1, 1)),
        (anios: 0, meses: 0, dias: 0),
      );
    });
  });

  test('describirHorizonte como en el mockup', () {
    expect(
      describirHorizonte(DateTime(2026, 8, 13), DateTime(2046, 8, 13)),
      'Mensaje para dentro de 20 años',
    );
    expect(
      describirHorizonte(DateTime(2026, 10, 3), DateTime(2027, 1, 5)),
      'Mensaje para dentro de 3 meses',
    );
    expect(
      describirHorizonte(DateTime(2026, 10, 3, 10), DateTime(2026, 10, 4, 8)),
      'Mensaje para dentro de 1 día',
    );
  });

  group('describirTiempoRestante', () {
    test('años, meses y días', () {
      expect(
        describirTiempoRestante(DateTime(2026, 10, 3), DateTime(2046, 8, 13)),
        'Faltan 19 años, 10 meses y 10 días',
      );
      expect(
        describirTiempoRestante(DateTime(2026, 10, 3), DateTime(2026, 10, 4, 1)),
        'Falta 1 día',
      );
    });

    test('horas y minutos el último día', () {
      expect(
        describirTiempoRestante(
          DateTime(2026, 10, 3, 10),
          DateTime(2026, 10, 3, 15, 12),
        ),
        'Faltan 5 h 12 min',
      );
      expect(
        describirTiempoRestante(
          DateTime(2026, 10, 3, 10),
          DateTime(2026, 10, 3, 10, 0, 30),
        ),
        'Falta menos de un minuto',
      );
    });

    test('cuando ya llegó', () {
      expect(
        describirTiempoRestante(DateTime(2026, 10, 3), DateTime(2026, 10, 2)),
        'Ya puedes abrirla',
      );
    });
  });
}
