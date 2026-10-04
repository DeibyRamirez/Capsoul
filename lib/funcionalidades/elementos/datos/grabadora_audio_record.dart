import 'dart:io';
import 'dart:math' as math;

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../dominio/grabadora_audio.dart';
import '../dominio/limites_medios.dart';

/// [GrabadoraAudio] con el paquete `record`: AAC-LC mono a 64 kbps (.m4a).
class GrabadoraAudioRecord implements GrabadoraAudio {
  GrabadoraAudioRecord() : _grabadora = AudioRecorder();

  final AudioRecorder _grabadora;

  /// Silencio de referencia en dBFS para normalizar la onda.
  static const double _pisoDecibeles = -45;

  static const Duration _intervaloNiveles = Duration(milliseconds: 120);

  @override
  Future<bool> tienePermiso() => _grabadora.hasPermission();

  @override
  Future<void> iniciar() async {
    final carpeta = await getTemporaryDirectory();
    final ruta = '${carpeta.path}${Platform.pathSeparator}'
        'capsoul_audio_${DateTime.now().microsecondsSinceEpoch}.m4a';
    await _grabadora.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: LimitesMedios.bitrateAudio,
        sampleRate: LimitesMedios.frecuenciaMuestreoAudio,
        numChannels: LimitesMedios.canalesAudio,
      ),
      path: ruta,
    );
  }

  @override
  Future<String?> detener() => _grabadora.stop();

  @override
  Future<void> cancelar() => _grabadora.cancel();

  @override
  Stream<double> niveles() {
    return _grabadora.onAmplitudeChanged(_intervaloNiveles).map((amplitud) {
      final decibeles = amplitud.current.isFinite ? amplitud.current : -160.0;
      final normalizado = 1 - (decibeles / _pisoDecibeles);
      return math.min(1, math.max(0, normalizado)).toDouble();
    });
  }

  @override
  Future<void> liberar() => _grabadora.dispose();
}
