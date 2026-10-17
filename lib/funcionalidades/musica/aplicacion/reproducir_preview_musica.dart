import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

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

/// [AudioSource] para el clip de ~30 s.
AudioSource fuenteAudioPreview(ReferenciaMusica referencia) {
  final url = referencia.previewUrl!.trim();
  return AudioSource.uri(
    Uri.parse(url),
    headers: cabecerasPreview(referencia),
  );
}

Future<void> _cargarPreviewDesdeDescargaTemporal(
  AudioPlayer reproductor,
  ReferenciaMusica referencia,
) async {
  final url = referencia.previewUrl!.trim();
  final headers = cabecerasPreview(referencia);
  final respuesta = await http.get(Uri.parse(url), headers: headers);
  if (respuesta.statusCode < 200 || respuesta.statusCode >= 300) {
    throw StateError(
      'preview_http_${respuesta.statusCode}:${Uri.parse(url).host}',
    );
  }
  final dir = await getTemporaryDirectory();
  final archivo = File(
    '${dir.path}/capsoul_preview_${referencia.idExterno.hashCode}.mp3',
  );
  await archivo.writeAsBytes(respuesta.bodyBytes, flush: true);
  await reproductor.setFilePath(archivo.path);
  debugPrint('Capsoul: preview vía archivo temporal (${Uri.parse(url).host})');
}

/// Carga la fuente en el reproductor (stream y, si falla, descarga temporal).
Future<void> cargarPreviewEnReproductor(
  AudioPlayer reproductor,
  ReferenciaMusica referencia,
) async {
  final host = Uri.tryParse(referencia.previewUrl!.trim())?.host ?? '?';
  await reproductor.stop();
  try {
    await reproductor.setAudioSource(fuenteAudioPreview(referencia));
    debugPrint('Capsoul: preview vía stream ($host)');
  } catch (error) {
    debugPrint('Capsoul: preview stream falló ($host): $error');
    await _cargarPreviewDesdeDescargaTemporal(reproductor, referencia);
  }
}
