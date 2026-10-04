import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/errores/fallo_app.dart';
import '../../elementos/dominio/limites_medios.dart';
import '../../inicio/aplicacion/proveedores_inicio.dart';
import '../../recuerdos/dominio/recuerdo.dart';
import '../dominio/fallo_capsula.dart';
import '../dominio/nueva_capsula.dart';
import '../dominio/validador_capsula.dart';
import 'proveedores_capsulas.dart';

/// Estado del formulario "Nueva cápsula".
@immutable
class EstadoCrearCapsula {
  const EstadoCrearCapsula({
    this.recuerdos = const [],
    this.fechaApertura,
    this.guardando = false,
    this.error,
  });

  /// Recuerdos elegidos, en el orden en que se guardarán.
  final List<Recuerdo> recuerdos;
  final DateTime? fechaApertura;
  final bool guardando;
  final FalloApp? error;

  static const int maximo = LimitesMedios.elementosMaxPorCapsula;

  bool get llena => recuerdos.length >= maximo;

  /// Cuántos recuerdos más se pueden agregar.
  int get disponibles => maximo - recuerdos.length;

  Set<String> get idsElegidos => {for (final r in recuerdos) r.id};

  EstadoCrearCapsula copiarCon({
    List<Recuerdo>? recuerdos,
    DateTime? fechaApertura,
    bool? guardando,
    FalloApp? error,
    bool limpiarError = false,
  }) {
    return EstadoCrearCapsula(
      recuerdos: recuerdos ?? this.recuerdos,
      fechaApertura: fechaApertura ?? this.fechaApertura,
      guardando: guardando ?? this.guardando,
      error: limpiarError ? null : (error ?? this.error),
    );
  }
}

/// Agrega y quita recuerdos, elige la fecha y guarda la cápsula.
class ControladorCrearCapsula extends Notifier<EstadoCrearCapsula> {
  @override
  EstadoCrearCapsula build() => const EstadoCrearCapsula();

  /// Agrega [nuevos] sin duplicados y hasta el máximo. Devuelve cuántos se
  /// agregaron; si sobraron, deja el fallo de "demasiados" en el estado.
  int agregarRecuerdos(List<Recuerdo> nuevos) {
    final ids = state.idsElegidos;
    final lista = [...state.recuerdos];
    var sobraron = false;
    for (final recuerdo in nuevos) {
      if (!ids.add(recuerdo.id)) continue;
      if (lista.length >= EstadoCrearCapsula.maximo) {
        sobraron = true;
        break;
      }
      lista.add(recuerdo);
    }
    final agregados = lista.length - state.recuerdos.length;
    state = sobraron
        ? state.copiarCon(
            recuerdos: lista,
            error: const FalloCapsula.demasiadosElementos(),
          )
        : state.copiarCon(recuerdos: lista, limpiarError: true);
    return agregados;
  }

  void quitar(String idRecuerdo) {
    state = state.copiarCon(
      recuerdos: [
        for (final recuerdo in state.recuerdos)
          if (recuerdo.id != idRecuerdo) recuerdo,
      ],
      limpiarError: true,
    );
  }

  /// Lo llama la pantalla después de mostrar el error.
  void limpiarError() {
    if (state.error != null) state = state.copiarCon(limpiarError: true);
  }

  void elegirFecha(DateTime fecha) {
    state = state.copiarCon(fechaApertura: fecha, limpiarError: true);
  }

  /// Valida y guarda. Devuelve el id de la cápsula o `null` si falló (el
  /// fallo queda en [EstadoCrearCapsula.error]).
  Future<String?> guardar({required String titulo, String? mensaje}) async {
    if (state.guardando) return null;
    final fecha = state.fechaApertura;
    final ahora = ref.read(proveedorReloj)();
    if (fecha == null) {
      state = state.copiarCon(error: const FalloCapsula.fechaInvalida());
      return null;
    }
    final nueva = NuevaCapsula(
      titulo: titulo,
      mensaje: mensaje,
      fechaApertura: fecha,
      recuerdos: state.recuerdos,
    );
    final fallo = ValidadorCapsula.validar(nueva, ahora: ahora);
    if (fallo != null) {
      state = state.copiarCon(error: fallo);
      return null;
    }
    state = state.copiarCon(guardando: true, limpiarError: true);
    try {
      final id = await ref.read(proveedorRepositorioCapsulas).crearCapsula(
            nueva,
          );
      if (ref.mounted) {
        state = state.copiarCon(guardando: false);
        ref.invalidate(proveedorMisCapsulas);
        ref.invalidate(proveedorResumenInicio);
      }
      return id;
    } on FalloApp catch (fallo) {
      if (ref.mounted) state = state.copiarCon(guardando: false, error: fallo);
      return null;
    } catch (error) {
      debugPrint('Capsoul: error no esperado al guardar la cápsula: $error');
      if (ref.mounted) {
        state = state.copiarCon(
          guardando: false,
          error: const FalloCapsula.desconocido(),
        );
      }
      return null;
    }
  }
}

final proveedorControladorCrearCapsula =
    NotifierProvider.autoDispose<ControladorCrearCapsula, EstadoCrearCapsula>(
  ControladorCrearCapsula.new,
);
