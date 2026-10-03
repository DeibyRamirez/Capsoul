import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/errores/fallo_app.dart';
import '../dominio/elemento_borrador.dart';
import '../dominio/fallo_medios.dart';
import '../dominio/grabadora_audio.dart';
import '../dominio/limites_medios.dart';
import 'proveedores_elementos.dart';

enum FaseGrabacion { lista, grabando, procesando, terminada }

/// Estado de la grabadora de notas de voz.
@immutable
class EstadoGrabacionAudio {
  const EstadoGrabacionAudio({
    this.fase = FaseGrabacion.lista,
    this.transcurrido = Duration.zero,
    this.muestras = const [],
    this.resultado,
    this.error,
  });

  final FaseGrabacion fase;
  final Duration transcurrido;

  /// Niveles 0..1 recibidos durante la grabación (para la onda en vivo).
  final List<double> muestras;
  final ElementoBorrador? resultado;
  final FalloApp? error;

  Duration get restante => LimitesMedios.duracionMaxAudio - transcurrido;

  EstadoGrabacionAudio copiarCon({
    FaseGrabacion? fase,
    Duration? transcurrido,
    List<double>? muestras,
    ElementoBorrador? resultado,
    FalloApp? error,
    bool limpiarError = false,
  }) {
    return EstadoGrabacionAudio(
      fase: fase ?? this.fase,
      transcurrido: transcurrido ?? this.transcurrido,
      muestras: muestras ?? this.muestras,
      resultado: resultado ?? this.resultado,
      error: limpiarError ? null : (error ?? this.error),
    );
  }
}

/// Graba hasta [LimitesMedios.duracionMaxAudio] (se detiene sola) y prepara
/// el archivo con [proveedorCompresorMedios].
class ControladorGrabacionAudio extends Notifier<EstadoGrabacionAudio> {
  static const Duration intervaloReloj = Duration(milliseconds: 200);

  /// Cantidad de barras que se guardan para dibujar la onda de la nota.
  static const int barrasOnda = 48;

  GrabadoraAudio? _grabadora;
  Timer? _reloj;
  StreamSubscription<double>? _suscripcionNiveles;

  /// Copia de la fase para `onDispose` (ahí no se lee `state`).
  bool _grabando = false;

  @override
  EstadoGrabacionAudio build() {
    ref.onDispose(_liberar);
    return const EstadoGrabacionAudio();
  }

  GrabadoraAudio get _grabadoraActual =>
      _grabadora ??= ref.read(proveedorFabricaGrabadora)();

  Future<void> iniciar() async {
    if (state.fase != FaseGrabacion.lista) return;
    final grabadora = _grabadoraActual;
    state = state.copiarCon(limpiarError: true);
    try {
      if (!await grabadora.tienePermiso()) {
        if (ref.mounted) {
          state = state.copiarCon(error: const FalloMedios.permisoMicrofono());
        }
        return;
      }
      await grabadora.iniciar();
    } catch (error) {
      debugPrint('Capsoul: no se pudo iniciar la grabación: $error');
      if (ref.mounted) {
        state = state.copiarCon(error: const FalloMedios.capturaFallida());
      }
      return;
    }
    if (!ref.mounted) return;
    _grabando = true;
    state = const EstadoGrabacionAudio(fase: FaseGrabacion.grabando);
    _suscripcionNiveles = grabadora.niveles().listen((nivel) {
      if (state.fase == FaseGrabacion.grabando) {
        state = state.copiarCon(muestras: [...state.muestras, nivel]);
      }
    });
    _reloj = Timer.periodic(intervaloReloj, (_) => _alAvanzarReloj());
  }

  void _alAvanzarReloj() {
    if (state.fase != FaseGrabacion.grabando) return;
    final transcurrido = state.transcurrido + intervaloReloj;
    state = state.copiarCon(transcurrido: transcurrido);
    if (transcurrido >= LimitesMedios.duracionMaxAudio) detener();
  }

  Future<void> detener() async {
    if (state.fase != FaseGrabacion.grabando) return;
    _detenerReloj();
    state = state.copiarCon(fase: FaseGrabacion.procesando);
    try {
      final ruta = await _grabadoraActual.detener();
      if (ruta == null) throw const FalloMedios.capturaFallida();
      final elemento = await ref.read(proveedorCompresorMedios).prepararAudio(
            ruta,
            state.transcurrido,
            reducirMuestras(state.muestras, barrasOnda),
          );
      if (ref.mounted) {
        state = state.copiarCon(
          fase: FaseGrabacion.terminada,
          resultado: elemento,
        );
      }
    } on FalloApp catch (fallo) {
      if (ref.mounted) state = _reiniciadoConError(fallo);
    } catch (error) {
      debugPrint('Capsoul: error al terminar la grabación: $error');
      if (ref.mounted) {
        state = _reiniciadoConError(const FalloMedios.capturaFallida());
      }
    }
  }

  /// Descarta lo grabado y vuelve a empezar.
  Future<void> descartar() async {
    _detenerReloj();
    if (state.fase == FaseGrabacion.grabando) {
      await _grabadoraActual.cancelar();
    }
    if (ref.mounted) state = const EstadoGrabacionAudio();
  }

  EstadoGrabacionAudio _reiniciadoConError(FalloApp fallo) =>
      EstadoGrabacionAudio(error: fallo);

  void _detenerReloj() {
    _grabando = false;
    _reloj?.cancel();
    _reloj = null;
    _suscripcionNiveles?.cancel();
    _suscripcionNiveles = null;
  }

  void _liberar() {
    final grabadora = _grabadora;
    final grabando = _grabando;
    _detenerReloj();
    if (grabadora == null) return;
    unawaited(() async {
      try {
        if (grabando) await grabadora.cancelar();
        await grabadora.liberar();
      } catch (error) {
        debugPrint('Capsoul: error al liberar la grabadora: $error');
      }
    }());
  }
}

/// Reduce [muestras] a [cantidad] barras promediando tramos (para guardar la
/// onda de la nota de voz).
List<double> reducirMuestras(List<double> muestras, int cantidad) {
  if (muestras.isEmpty || cantidad <= 0) return const [];
  if (muestras.length <= cantidad) return List.unmodifiable(muestras);
  final resultado = <double>[];
  final tramo = muestras.length / cantidad;
  for (var i = 0; i < cantidad; i++) {
    final desde = (i * tramo).floor();
    final hasta = ((i + 1) * tramo).floor().clamp(desde + 1, muestras.length);
    var suma = 0.0;
    for (var j = desde; j < hasta; j++) {
      suma += muestras[j];
    }
    resultado.add(suma / (hasta - desde));
  }
  return List.unmodifiable(resultado);
}

final proveedorControladorGrabacionAudio = NotifierProvider.autoDispose<
    ControladorGrabacionAudio, EstadoGrabacionAudio>(
  ControladorGrabacionAudio.new,
);
