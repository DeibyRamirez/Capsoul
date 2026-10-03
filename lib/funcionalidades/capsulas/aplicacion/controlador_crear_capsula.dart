import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/errores/fallo_app.dart';
import '../../elementos/dominio/elemento_borrador.dart';
import '../../elementos/dominio/limites_medios.dart';
import '../../inicio/aplicacion/proveedores_inicio.dart';
import '../dominio/fallo_capsula.dart';
import '../dominio/nueva_capsula.dart';
import '../dominio/validador_capsula.dart';
import 'proveedores_capsulas.dart';

/// Estado del formulario "Nueva cápsula".
@immutable
class EstadoCrearCapsula {
  const EstadoCrearCapsula({
    this.elementos = const [],
    this.fechaApertura,
    this.guardando = false,
    this.guardados = 0,
    this.error,
  });

  final List<ElementoBorrador> elementos;
  final DateTime? fechaApertura;
  final bool guardando;

  /// Elementos ya guardados durante el guardado (para el progreso).
  final int guardados;
  final FalloApp? error;

  bool get llena => elementos.length >= LimitesMedios.elementosMaxPorCapsula;

  EstadoCrearCapsula copiarCon({
    List<ElementoBorrador>? elementos,
    DateTime? fechaApertura,
    bool? guardando,
    int? guardados,
    FalloApp? error,
    bool limpiarError = false,
  }) {
    return EstadoCrearCapsula(
      elementos: elementos ?? this.elementos,
      fechaApertura: fechaApertura ?? this.fechaApertura,
      guardando: guardando ?? this.guardando,
      guardados: guardados ?? this.guardados,
      error: limpiarError ? null : (error ?? this.error),
    );
  }
}

/// Agrega y quita elementos, elige la fecha y guarda la cápsula.
class ControladorCrearCapsula extends Notifier<EstadoCrearCapsula> {
  @override
  EstadoCrearCapsula build() => const EstadoCrearCapsula();

  /// `false` si la cápsula ya tiene el máximo de elementos.
  bool agregarElemento(ElementoBorrador elemento) {
    if (state.llena) {
      state = state.copiarCon(error: const FalloCapsula.demasiadosElementos());
      return false;
    }
    if (state.elementos.any((e) => e.idLocal == elemento.idLocal)) return true;
    state = state.copiarCon(
      elementos: [...state.elementos, elemento],
      limpiarError: true,
    );
    return true;
  }

  void quitarElemento(String idLocal) {
    state = state.copiarCon(
      elementos: [
        for (final elemento in state.elementos)
          if (elemento.idLocal != idLocal) elemento,
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
      elementos: state.elementos,
    );
    final fallo = ValidadorCapsula.validar(nueva, ahora: ahora);
    if (fallo != null) {
      state = state.copiarCon(error: fallo);
      return null;
    }
    state = state.copiarCon(guardando: true, guardados: 0, limpiarError: true);
    try {
      final id = await ref.read(proveedorRepositorioCapsulas).crearCapsula(
        nueva,
        alProgreso: (guardados, _) {
          if (ref.mounted) state = state.copiarCon(guardados: guardados);
        },
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
