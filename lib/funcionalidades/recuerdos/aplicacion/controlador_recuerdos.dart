import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/errores/fallo_app.dart';
import '../../inicio/aplicacion/proveedores_inicio.dart';
import '../dominio/fallo_recuerdo.dart';
import '../dominio/nuevo_recuerdo.dart';
import '../dominio/recuerdo.dart';
import 'proveedores_recuerdos.dart';

/// Estado de una acción sobre recuerdos (guardar o borrar).
@immutable
class EstadoAccionRecuerdo {
  const EstadoAccionRecuerdo({this.ocupado = false, this.error});

  final bool ocupado;
  final FalloApp? error;
}

/// Guarda y borra recuerdos y refresca las listas, el uso y el resumen.
class ControladorRecuerdos extends Notifier<EstadoAccionRecuerdo> {
  @override
  EstadoAccionRecuerdo build() => const EstadoAccionRecuerdo();

  /// Devuelve el recuerdo guardado o `null` (el fallo queda en el estado).
  Future<Recuerdo?> guardar(NuevoRecuerdo nuevo) =>
      _ejecutar(() => ref.read(proveedorRepositorioRecuerdos).crear(nuevo));

  /// Borra [recuerdo]. `true` si se borró.
  Future<bool> eliminar(Recuerdo recuerdo) async {
    final resultado = await _ejecutar(() async {
      await ref.read(proveedorRepositorioRecuerdos).eliminar(recuerdo.id);
      return true;
    });
    return resultado ?? false;
  }

  void limpiarError() {
    if (state.error != null) state = EstadoAccionRecuerdo(ocupado: state.ocupado);
  }

  Future<T?> _ejecutar<T>(Future<T> Function() accion) async {
    if (state.ocupado) return null;
    state = const EstadoAccionRecuerdo(ocupado: true);
    try {
      final resultado = await accion();
      if (ref.mounted) {
        state = const EstadoAccionRecuerdo();
        ref.invalidate(proveedorRecuerdos);
        ref.invalidate(proveedorRecuerdo);
        ref.invalidate(proveedorUsoMedios);
        ref.invalidate(proveedorResumenInicio);
      }
      return resultado;
    } on FalloApp catch (fallo) {
      if (ref.mounted) state = EstadoAccionRecuerdo(error: fallo);
      return null;
    } catch (error) {
      debugPrint('Capsoul: error no esperado en recuerdos: $error');
      if (ref.mounted) {
        state = const EstadoAccionRecuerdo(error: FalloRecuerdo.desconocido());
      }
      return null;
    }
  }
}

final proveedorControladorRecuerdos =
    NotifierProvider.autoDispose<ControladorRecuerdos, EstadoAccionRecuerdo>(
  ControladorRecuerdos.new,
);
