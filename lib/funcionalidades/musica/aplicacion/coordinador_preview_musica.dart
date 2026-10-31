import 'package:just_audio/just_audio.dart';

/// Lleva el reproductor que está sonando y pausa el anterior cuando otro
/// empieza, para que nunca suenen dos previews a la vez.
class CoordinadorPreviewMusica {
  AudioPlayer? _activo;

  AudioPlayer? get activo => _activo;

  /// Marca [reproductor] como el único activo y pausa el anterior.
  Future<void> tomar(AudioPlayer reproductor) async {
    final anterior = _activo;
    _activo = reproductor;
    if (anterior != null && !identical(anterior, reproductor)) {
      try {
        await anterior.pause();
      } catch (_) {
        // El reproductor anterior pudo liberarse ya.
      }
    }
  }

  /// Olvida [reproductor] si era el activo (al cerrar la pantalla).
  void soltar(AudioPlayer reproductor) {
    if (identical(_activo, reproductor)) _activo = null;
  }

  /// Pausa lo que suene (p. ej. antes de abrir otra app).
  Future<void> pausarTodo() async {
    try {
      await _activo?.pause();
    } catch (_) {
      // Ignorar si ya se liberó.
    }
  }
}
