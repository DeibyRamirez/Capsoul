import 'package:just_audio/just_audio.dart';

import '../dominio/referencia_musica.dart';

/// [AudioSource] en streaming para el clip de ~30 s.
///
/// Sin headers, sin caché y sin proxy: en Android, just_audio levanta un
/// proxy HTTP local (http://127.0.0.1) cuando se pasan headers o se usa
/// LockCachingAudioSource/StreamAudioSource, y Android bloquea ese tráfico
/// en texto plano («Cleartext HTTP traffic to 127.0.0.1 not permitted»).
/// La URL https de Deezer se reproduce directo con ExoPlayer/AVPlayer.
AudioSource fuenteAudioPreview(ReferenciaMusica referencia) {
  return AudioSource.uri(Uri.parse(referencia.previewUrl!.trim()));
}

/// Carga el clip en el reproductor por streaming desde la URL (no se
/// descarga a disco).
Future<void> cargarPreviewEnReproductor(
  AudioPlayer reproductor,
  ReferenciaMusica referencia,
) async {
  await reproductor.stop();
  await reproductor.setAudioSource(fuenteAudioPreview(referencia));
}
