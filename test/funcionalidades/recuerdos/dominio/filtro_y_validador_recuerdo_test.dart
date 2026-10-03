import 'package:capsoul/funcionalidades/elementos/dominio/elemento_borrador.dart';
import 'package:capsoul/funcionalidades/elementos/dominio/tipo_elemento.dart';
import 'package:capsoul/funcionalidades/recuerdos/dominio/fallo_recuerdo.dart';
import 'package:capsoul/funcionalidades/recuerdos/dominio/filtro_recuerdos.dart';
import 'package:capsoul/funcionalidades/recuerdos/dominio/nuevo_recuerdo.dart';
import 'package:capsoul/funcionalidades/recuerdos/dominio/validador_recuerdo.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../ayudantes/falsos_recuerdos.dart';

void main() {
  final hoy = DateTime(2026, 10, 3, 18);

  group('FiltroRecuerdos', () {
    test('todos admite cualquier recuerdo', () {
      expect(FiltroRecuerdos.todos.esVacio, isTrue);
      expect(FiltroRecuerdos.todos.admite(recuerdoPrueba('a')), isTrue);
    });

    test('filtra por tipo y alterna tipos', () {
      final filtro = FiltroRecuerdos.todos.alternarTipo(TipoElemento.video);
      expect(filtro.admite(recuerdoPrueba('a')), isFalse);
      expect(
        filtro.admite(recuerdoPrueba('b', tipo: TipoElemento.video)),
        isTrue,
      );
      expect(filtro.alternarTipo(TipoElemento.video), FiltroRecuerdos.todos);
    });

    test('últimos 7 días incluye ambos extremos', () {
      final filtro = FiltroRecuerdos.ultimosDias(7, hoy);
      expect(filtro.desde, DateTime(2026, 9, 27));
      expect(filtro.hasta, DateTime(2026, 10, 3));
      expect(
        filtro.admite(recuerdoPrueba('a', fecha: DateTime(2026, 9, 27))),
        isTrue,
      );
      expect(
        filtro.admite(recuerdoPrueba('b', fecha: DateTime(2026, 9, 26))),
        isFalse,
      );
    });

    test('este año empieza el 1 de enero', () {
      final filtro = FiltroRecuerdos.esteAnio(hoy);
      expect(filtro.desde, DateTime(2026));
      expect(
        filtro.admite(recuerdoPrueba('a', fecha: DateTime(2025, 12, 31))),
        isFalse,
      );
    });

    test('la igualdad no depende del orden de los tipos', () {
      const a = FiltroRecuerdos(tipos: {TipoElemento.foto, TipoElemento.audio});
      const b = FiltroRecuerdos(tipos: {TipoElemento.audio, TipoElemento.foto});
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });

  group('ValidadorRecuerdo', () {
    const nota = ElementoBorrador(
      idLocal: 'n',
      tipo: TipoElemento.texto,
      texto: 'Hola',
      bytes: 4,
    );

    test('título opcional de hasta 120 caracteres', () {
      expect(ValidadorRecuerdo.validarTitulo(null), isNull);
      expect(ValidadorRecuerdo.validarTitulo('   '), isNull);
      expect(ValidadorRecuerdo.validarTitulo('ñ' * 120), isNull);
      expect(
        ValidadorRecuerdo.validarTitulo('a' * 121)?.codigo,
        FalloRecuerdo.codigoTituloInvalido,
      );
    });

    test('la fecha no puede ser futura ni anterior a 1900', () {
      expect(ValidadorRecuerdo.validarFecha(DateTime(2026, 10, 3), hoy: hoy),
          isNull);
      expect(
        ValidadorRecuerdo.validarFecha(DateTime(2026, 10, 4), hoy: hoy)?.codigo,
        FalloRecuerdo.codigoFechaInvalida,
      );
      expect(
        ValidadorRecuerdo.validarFecha(DateTime(1899, 12, 31), hoy: hoy)
            ?.codigo,
        FalloRecuerdo.codigoFechaInvalida,
      );
    });

    test('validar combina título y fecha', () {
      expect(
        ValidadorRecuerdo.validar(
          NuevoRecuerdo(elemento: nota, fechaRecuerdo: DateTime(2020)),
          hoy: hoy,
        ),
        isNull,
      );
    });
  });
}
