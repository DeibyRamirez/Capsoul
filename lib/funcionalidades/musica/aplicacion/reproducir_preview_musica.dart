import 'package:just_audio/just_audio.dart';

import '../dominio/referencia_musica.dart';

const _userAgentNavegador =
    'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 '
    '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';

/// Cabeceras HTTP para CDNs de preview (Spotify / Deezer).
Map<String, String> cabecerasPreview(ReferenciaMusica referencia) {
  final url = referencia.previewUrl?.trim() ?? '';
  final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
  final headers = <String, String>{
    'User-Agent': _userAgentNavegador,
    'Accept': '*/*',
  };
  if (host.contains('dzcdn') || host.contains('deezer')) {
    headers['Referer'] = 'https://www.deezer.com/';
  } else if (host.contains('scdn') || host.contains('spotify')) {
    headers['Referer'] = 'https://open.spotify.com/';
  }
  return headers;
}

/// [AudioSource] en streaming para el clip de ~30 s (no se guarda a disco).
AudioSource fuenteAudioPreview(ReferenciaMusica referencia) {
  final url = referencia.previewUrl!.trim();
  return AudioSource.uri(
    Uri.parse(url),
    headers: cabecerasPreview(referencia),
  );
}

/// Carga el clip en el reproductor por streaming desde la URL.
Future<void> cargarPreviewEnReproductor(
  AudioPlayer reproductor,
  ReferenciaMusica referencia,
) async {
  await reproductor.stop();
  await reproductor.setAudioSource(fuenteAudioPreview(referencia));
}
