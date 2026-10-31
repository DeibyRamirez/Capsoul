import 'package:just_audio/just_audio.dart';

import '../dominio/fallo_musica.dart';
import '../dominio/referencia_musica.dart';
import '../dominio/repositorio_catalogo_musica.dart';
import '../dominio/url_preview_musica.dart';
import 'refrescar_preview_musica.dart';
import 'reproducir_preview_musica.dart';

/// Resultado de cargar preview, con la referencia que se usó.
class ResultadoCargaPreview {
  const ResultadoCargaPreview({
    required this.referencia,
    this.refrescada = false,
  });

  final ReferenciaMusica referencia;

  /// True si una fila antigua (con URL guardada) obtuvo una URL nueva y
  /// conviene persistirla. En Deezer nunca se persiste la URL.
  final bool refrescada;
}

bool _previewListoParaStreaming(ReferenciaMusica referencia) =>
    urlPreviewConfiable(referencia.previewUrl);

/// Prepara y carga el preview en streaming.
///
/// Si no hay URL (pista de Deezer guardada) la pide por id antes; si la URL
/// falla (caducada), la vuelve a pedir y reintenta una vez.
/// Lanza [FalloMusica] con [TipoFalloMusica.sinPreview] si no hay clip.
Future<ResultadoCargaPreview> intentarCargarPreviewConRefresco(
  AudioPlayer reproductor,
  ReferenciaMusica referencia,
  RepositorioCatalogoMusica catalogo,
) async {
  var actual = referencia;
  var pedida = false;
  if (!_previewListoParaStreaming(actual)) {
    final fresca = await refrescarPreview(actual, catalogo);
    if (fresca == null || !_previewListoParaStreaming(fresca)) {
      throw const FalloMusica(TipoFalloMusica.sinPreview);
    }
    actual = fresca;
    pedida = true;
  }
  try {
    await cargarPreviewEnReproductor(reproductor, actual);
    return ResultadoCargaPreview(
      referencia: actual,
      refrescada: pedida && !actual.esDeezer,
    );
  } catch (error, pila) {
    if (pedida) Error.throwWithStackTrace(error, pila);
    final fresca = await refrescarPreview(actual, catalogo);
    if (fresca == null || !_previewListoParaStreaming(fresca)) {
      Error.throwWithStackTrace(error, pila);
    }
    await cargarPreviewEnReproductor(reproductor, fresca);
    return ResultadoCargaPreview(
      referencia: fresca,
      refrescada: !fresca.esDeezer,
    );
  }
}
