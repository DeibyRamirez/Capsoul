import '../../elementos/dominio/limites_medios.dart';
import '../../elementos/dominio/validador_medios.dart';
import 'fallo_capsula.dart';
import 'nueva_capsula.dart';

/// Reglas de una cápsula nueva (coherentes con la migración: título 1..120,
/// fecha de apertura al menos 1 minuto en el futuro, 1..10 elementos).
abstract final class ValidadorCapsula {
  static const int caracteresMaxTitulo = 120;

  /// Margen que exige el trigger `privado.validar_capsula`.
  static const Duration margenMinimoApertura = Duration(minutes: 1);

  static FalloCapsula? validarTitulo(String titulo) {
    final caracteres = contarCaracteres(titulo.trim());
    if (caracteres < 1 || caracteres > caracteresMaxTitulo) {
      return const FalloCapsula.tituloInvalido();
    }
    return null;
  }

  static FalloCapsula? validarFecha(DateTime fecha, {required DateTime ahora}) {
    if (!fecha.isAfter(ahora.add(margenMinimoApertura))) {
      return const FalloCapsula.fechaInvalida();
    }
    return null;
  }

  static FalloCapsula? validarCantidad(int cantidad) {
    if (cantidad < 1) return const FalloCapsula.sinElementos();
    if (cantidad > LimitesMedios.elementosMaxPorCapsula) {
      return const FalloCapsula.demasiadosElementos();
    }
    return null;
  }

  /// Primer problema de [nueva] o `null` si se puede guardar.
  static FalloCapsula? validar(NuevaCapsula nueva, {required DateTime ahora}) {
    return validarTitulo(nueva.titulo) ??
        validarFecha(nueva.fechaApertura, ahora: ahora) ??
        validarCantidad(nueva.elementos.length);
  }

  /// Primer día que se puede elegir en el selector de fecha (mañana).
  static DateTime primerDiaSeleccionable(DateTime ahora) =>
      DateTime(ahora.year, ahora.month, ahora.day + 1);
}
