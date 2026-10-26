import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/errores/fallo_app.dart';
import '../../elementos/dominio/limites_medios.dart';
import '../../inicio/aplicacion/proveedores_inicio.dart';
import '../../recuerdos/dominio/recuerdo.dart';
import '../dominio/fallo_capsula.dart';
import '../dominio/validador_capsula.dart';
import 'proveedores_capsulas.dart';

/// Estado del formulario de edición de cápsula.
@immutable
class EstadoEditarCapsula {
  const EstadoEditarCapsula({
    this.recuerdos = const [],
    this.fechaApertura,
    this.destinatariosUsuarioIds = const {},
    this.guardando = false,
    this.error,
    this.inicializado = false,
  });

  final List<Recuerdo> recuerdos;
  final DateTime? fechaApertura;
  final Set<String> destinatariosUsuarioIds;
  final bool guardando;
  final FalloApp? error;
  final bool inicializado;

  static const int maximo = LimitesMedios.elementosMaxPorCapsula;

  bool get llena => recuerdos.length >= maximo;

  int get disponibles => maximo - recuerdos.length;

  Set<String> get idsElegidos => {for (final r in recuerdos) r.id};

  EstadoEditarCapsula copiarCon({
    List<Recuerdo>? recuerdos,
    DateTime? fechaApertura,
    Set<String>? destinatariosUsuarioIds,
    bool? guardando,
    FalloApp? error,
    bool? inicializado,
    bool limpiarError = false,
  }) {
    return EstadoEditarCapsula(
      recuerdos: recuerdos ?? this.recuerdos,
      fechaApertura: fechaApertura ?? this.fechaApertura,
      destinatariosUsuarioIds:
          destinatariosUsuarioIds ?? this.destinatariosUsuarioIds,
      guardando: guardando ?? this.guardando,
      error: limpiarError ? null : (error ?? this.error),
      inicializado: inicializado ?? this.inicializado,
    );
  }
}

class ControladorEditarCapsula extends Notifier<EstadoEditarCapsula> {
  @override
  EstadoEditarCapsula build() => const EstadoEditarCapsula();

  void cargarDesde({
    required List<Recuerdo> recuerdos,
    required DateTime? fechaApertura,
    required List<String> destinatariosUsuarioIds,
  }) {
    if (state.inicializado) return;
    state = state.copiarCon(
      recuerdos: recuerdos,
      fechaApertura: fechaApertura,
      destinatariosUsuarioIds: destinatariosUsuarioIds.toSet(),
      inicializado: true,
      limpiarError: true,
    );
  }

  int agregarRecuerdos(List<Recuerdo> nuevos) {
    final ids = state.idsElegidos;
    final lista = [...state.recuerdos];
    var sobraron = false;
    for (final recuerdo in nuevos) {
      if (!ids.add(recuerdo.id)) continue;
      if (lista.length >= EstadoEditarCapsula.maximo) {
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

  void limpiarError() {
    if (state.error != null) state = state.copiarCon(limpiarError: true);
  }

  void elegirFecha(DateTime fecha) {
    state = state.copiarCon(fechaApertura: fecha, limpiarError: true);
  }

  void elegirDestinatarios(Set<String> usuarioIds) {
    state = state.copiarCon(
      destinatariosUsuarioIds: usuarioIds,
      limpiarError: true,
    );
  }

  Future<bool> guardar({
    required String idCapsula,
    required String titulo,
    String? mensaje,
  }) async {
    if (state.guardando) return false;
    final fecha = state.fechaApertura;
    final destinatarios = state.destinatariosUsuarioIds.toList();
    final ahora = ref.read(proveedorReloj)();
    if (fecha == null) {
      state = state.copiarCon(error: const FalloCapsula.fechaInvalida());
      return false;
    }
    final falloDest = ValidadorCapsula.validarDestinatarios(destinatarios);
    if (falloDest != null) {
      state = state.copiarCon(error: falloDest);
      return false;
    }
    final falloTitulo = ValidadorCapsula.validarTitulo(titulo);
    if (falloTitulo != null) {
      state = state.copiarCon(error: falloTitulo);
      return false;
    }
    final falloFecha = ValidadorCapsula.validarFecha(fecha, ahora: ahora);
    if (falloFecha != null) {
      state = state.copiarCon(error: falloFecha);
      return false;
    }
    final falloCantidad = ValidadorCapsula.validarCantidad(state.recuerdos.length);
    if (falloCantidad != null) {
      state = state.copiarCon(error: falloCantidad);
      return false;
    }

    state = state.copiarCon(guardando: true, limpiarError: true);
    try {
      await ref.read(proveedorRepositorioCapsulas).actualizarCapsulaEditable(
            idCapsula,
            titulo: titulo,
            mensaje: mensaje,
            fechaApertura: fecha,
            idsRecuerdosOrdenados: [
              for (final r in state.recuerdos) r.id,
            ],
            destinatariosUsuarioIds: destinatarios,
          );
      if (ref.mounted) {
        state = state.copiarCon(guardando: false);
        ref.invalidate(proveedorCapsula(idCapsula));
        ref.invalidate(proveedorMisCapsulas);
        ref.invalidate(proveedorResumenInicio);
      }
      return true;
    } on FalloApp catch (fallo) {
      if (ref.mounted) state = state.copiarCon(guardando: false, error: fallo);
      return false;
    } catch (error) {
      debugPrint('Capsoul: error no esperado al editar la cápsula: $error');
      if (ref.mounted) {
        state = state.copiarCon(
          guardando: false,
          error: const FalloCapsula.desconocido(),
        );
      }
      return false;
    }
  }
}

final proveedorControladorEditarCapsula =
    NotifierProvider.autoDispose<ControladorEditarCapsula, EstadoEditarCapsula>(
  ControladorEditarCapsula.new,
);
