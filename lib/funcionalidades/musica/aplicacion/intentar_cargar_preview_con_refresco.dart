import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../dominio/referencia_musica.dart';
import '../dominio/repositorio_catalogo_musica.dart';
import 'refrescar_preview_musica.dart';
import 'reproducir_preview_musica.dart';

/// Resultado de cargar preview, con posible URL actualizada desde catálogo.
class ResultadoCargaPreview {
  const ResultadoCargaPreview({
    required this.referencia,
    this.refrescada = false,
  });

  final ReferenciaMusica referencia;
  final bool refrescada;
}

/// Carga el preview; si falla, busca de nuevo la pista y reintenta una vez.
Future<ResultadoCargaPreview> intentarCargarPreviewConRefresco(
  AudioPlayer reproductor,
  ReferenciaMusica referencia,
  RepositorioCatalogoMusica catalogo,
) async {
  try {
    await cargarPreviewEnReproductor(reproductor, referencia);
    return ResultadoCargaPreview(referencia: referencia);
  } catch (error, stack) {
    debugPrint('Capsoul: preview falló, intentando refresh: $error');
    final actualizada = await refrescarPreview(referencia, catalogo);
    if (actualizada == null) {
      Error.throwWithStackTrace(error, stack);
    }
    debugPrint('Capsoul: preview refrescado desde catálogo');
    await cargarPreviewEnReproductor(reproductor, actualizada);
    return ResultadoCargaPreview(
      referencia: actualizada,
      refrescada: true,
    );
  }
}
