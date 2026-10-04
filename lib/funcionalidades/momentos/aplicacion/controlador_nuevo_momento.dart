import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/errores/fallo_app.dart';
import '../../inicio/aplicacion/proveedores_inicio.dart';
import '../../recuerdos/dominio/recuerdo.dart';
import '../dominio/fallo_momento.dart';
import '../dominio/nuevo_momento.dart';
import '../dominio/validador_momento.dart';
import 'proveedores_momentos.dart';

/// Estado del formulario "Nuevo momento".
@immutable
class EstadoNuevoMomento {
  const EstadoNuevoMomento({
    this.recuerdos = const [],
    this.portadaId,
    this.guardando = false,
    this.error,
  });

  final List<Recuerdo> recuerdos;
  final String? portadaId;
  final bool guardando;
  final FalloApp? error;

  int get disponibles => ValidadorMomento.recuerdosMax - recuerdos.length;
  Set<String> get idsElegidos => {for (final r in recuerdos) r.id};
  List<Recuerdo> get visuales => [for (final r in recuerdos) if (r.esVisual) r];
}

/// Agrega recuerdos (a mano o todos los de un filtro), elige la portada y
/// guarda el momento.
class ControladorNuevoMomento extends Notifier<EstadoNuevoMomento> {
  @override
  EstadoNuevoMomento build() => const EstadoNuevoMomento();

  void _fijar({
    List<Recuerdo>? recuerdos,
    String? portadaId,
    bool quitarPortada = false,
    bool? guardando,
    FalloApp? error,
  }) {
    state = EstadoNuevoMomento(
      recuerdos: recuerdos ?? state.recuerdos,
      portadaId: quitarPortada ? null : (portadaId ?? state.portadaId),
      guardando: guardando ?? state.guardando,
      error: error,
    );
  }

  /// Agrega sin duplicados hasta el máximo; la primera foto o video queda
  /// como portada si aún no hay. Devuelve cuántos se agregaron.
  int agregar(List<Recuerdo> nuevos) {
    final antes = state.recuerdos.length;
    final ids = state.idsElegidos;
    final lista = [...state.recuerdos];
    var sobraron = false;
    for (final recuerdo in nuevos) {
      if (!ids.add(recuerdo.id)) continue;
      if (lista.length >= ValidadorMomento.recuerdosMax) {
        sobraron = true;
        break;
      }
      lista.add(recuerdo);
    }
    final portada = state.portadaId ??
        lista.where((r) => r.esVisual).map((r) => r.id).firstOrNull;
    _fijar(
      recuerdos: lista,
      portadaId: portada,
      error: sobraron ? const FalloMomento.demasiadosRecuerdos() : null,
    );
    return lista.length - antes;
  }

  void quitar(String id) {
    final lista = [for (final r in state.recuerdos) if (r.id != id) r];
    if (state.portadaId == id) {
      final otra = lista.where((r) => r.esVisual).map((r) => r.id).firstOrNull;
      _fijar(recuerdos: lista, portadaId: otra, quitarPortada: otra == null);
    } else {
      _fijar(recuerdos: lista);
    }
  }

  void elegirPortada(String id) => _fijar(portadaId: id);

  void limpiarError() {
    if (state.error != null) _fijar();
  }

  /// Devuelve el id del momento o `null` (el fallo queda en el estado).
  Future<String?> guardar({required String titulo, String? descripcion}) async {
    if (state.guardando) return null;
    final nuevo = NuevoMomento(
      titulo: titulo,
      descripcion: descripcion,
      recuerdos: state.recuerdos,
      portadaId: state.portadaId,
    );
    final fallo = ValidadorMomento.validar(nuevo);
    if (fallo != null) {
      _fijar(error: fallo);
      return null;
    }
    _fijar(guardando: true);
    try {
      final id = await ref.read(proveedorRepositorioMomentos).crear(nuevo);
      if (ref.mounted) {
        _fijar(guardando: false);
        ref.invalidate(proveedorMomentos);
        ref.invalidate(proveedorResumenInicio);
      }
      return id;
    } on FalloApp catch (fallo) {
      if (ref.mounted) _fijar(guardando: false, error: fallo);
      return null;
    } catch (error) {
      debugPrint('Capsoul: error no esperado al guardar el momento: $error');
      if (ref.mounted) {
        _fijar(guardando: false, error: const FalloMomento.desconocido());
      }
      return null;
    }
  }
}

final proveedorControladorNuevoMomento =
    NotifierProvider.autoDispose<ControladorNuevoMomento, EstadoNuevoMomento>(
  ControladorNuevoMomento.new,
);
