import '../../elementos/dominio/validador_medios.dart';
import 'fallo_recuerdo.dart';
import 'filtro_recuerdos.dart';
import 'nuevo_recuerdo.dart';

/// Reglas de un recuerdo nuevo (coherentes con la migración 000004: título
/// opcional de hasta 120 caracteres, fecha desde 1900 y no futura).
abstract final class ValidadorRecuerdo {
  static const int caracteresMaxTitulo = 120;
  static final DateTime primeraFecha = DateTime(1900);

  static FalloRecuerdo? validarTitulo(String? titulo) {
    if (titulo == null || titulo.trim().isEmpty) return null;
    if (contarCaracteres(titulo.trim()) > caracteresMaxTitulo) {
      return const FalloRecuerdo.tituloInvalido();
    }
    return null;
  }

  static FalloRecuerdo? validarFecha(DateTime fecha, {required DateTime hoy}) {
    final dia = FiltroRecuerdos.soloDia(fecha);
    if (dia.isAfter(FiltroRecuerdos.soloDia(hoy)) ||
        dia.isBefore(primeraFecha)) {
      return const FalloRecuerdo.fechaInvalida();
    }
    return null;
  }

  static FalloRecuerdo? validar(NuevoRecuerdo nuevo, {required DateTime hoy}) =>
      validarTitulo(nuevo.titulo) ?? validarFecha(nuevo.fechaRecuerdo, hoy: hoy);
}
