import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../elementos/dominio/elemento_borrador.dart';
import '../dominio/configuracion_crear.dart';
import '../dominio/modo_captura.dart';
import 'estado_hub_captura.dart';

/// Estado de la sesión de captura del hub (modo, duración, progreso).
class ControladorSesionCaptura extends Notifier<EstadoHubCaptura> {
  final progresoGrabacion = ValueNotifier<double>(0);
  Timer? _reloj;

  @override
  EstadoHubCaptura build() {
    ref.onDispose(() {
      _reloj?.cancel();
      progresoGrabacion.dispose();
    });
    const config = ConfiguracionCrear.porDefecto;
    final primeraDuracion = config.duracionesVideo.first;
    return EstadoHubCaptura(
      modo: config.modos.contains(ModoCaptura.video)
          ? ModoCaptura.video
          : config.modos.first,
      duracionMaxima: primeraDuracion,
    );
  }

  void elegirModo(ModoCaptura modo) {
    if (state.bloquearModos || state.modo == modo) return;
    state = state.copyWith(modo: modo, limpiarCaptura: true);
  }

  void elegirDuracion(Duration duracion) {
    if (state.grabando) return;
    state = state.copyWith(duracionMaxima: duracion);
  }

  void marcarProcesando(bool valor) {
    state = state.copyWith(procesando: valor);
  }

  void establecerCapturaLista(ElementoBorrador? borrador) {
    state = state.copyWith(
      capturaLista: borrador,
      limpiarCaptura: borrador == null,
      grabando: false,
      procesando: false,
      transcurrido: Duration.zero,
    );
    _actualizarProgreso(0);
  }

  void repetirCaptura() {
    state = state.copyWith(limpiarCaptura: true, transcurrido: Duration.zero);
    _actualizarProgreso(0);
  }

  void iniciarGrabacion() {
    state = state.copyWith(grabando: true, transcurrido: Duration.zero);
    _reloj?.cancel();
    _reloj = Timer.periodic(const Duration(milliseconds: 250), (_) {
      final siguiente = state.transcurrido + const Duration(milliseconds: 250);
      state = state.copyWith(transcurrido: siguiente);
      _actualizarProgreso(state.progresoGrabacion);
    });
  }

  void detenerGrabacion() {
    _reloj?.cancel();
    state = state.copyWith(grabando: false);
    _actualizarProgreso(state.progresoGrabacion);
  }

  void tickGrabacion(Duration transcurrido) {
    state = state.copyWith(transcurrido: transcurrido);
    _actualizarProgreso(state.progresoGrabacion);
  }

  void _actualizarProgreso(double valor) {
    progresoGrabacion.value = valor.clamp(0.0, 1.0);
  }

  void bloquearModos(bool valor) {
    state = state.copyWith(bloquearModos: valor);
  }
}

final proveedorControladorSesionCaptura =
    NotifierProvider.autoDispose<ControladorSesionCaptura, EstadoHubCaptura>(
  ControladorSesionCaptura.new,
);
