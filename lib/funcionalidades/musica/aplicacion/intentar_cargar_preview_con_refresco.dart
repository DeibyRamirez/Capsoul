import 'package:just_audio/just_audio.dart';

import '../dominio/fallo_musica.dart';
import '../dominio/referencia_musica.dart';
import '../dominio/repositorio_catalogo_musica.dart';
import 'refrescar_preview_musica.dart';
import 'reproducir_preview_musica.dart';

/// Resultado de cargar preview, con la referencia que se usó.
class ResultadoCargaPreview {
  const ResultadoCargaPreview({
    required this.referencia,
    this.refrescada = false,
  });

  /// Referencia con la URL que se reprodujo. Si la URL es de Deezer, vive
  /// solo en memoria: caduca y nunca se guarda en la base de datos.
  final ReferenciaMusica referencia;

  /// True solo si la URL nueva no es de Deezer y conviene persistirla.
  /// Como el catálogo actual es Deezer, en la práctica siempre es false.
  final bool refrescada;
}

/// True si la URL guardada no sirve y hay que pedir `/track/<id>` a Deezer:
/// pistas de Deezer o filas antiguas cuyo preview guardado era de Deezer
/// (esas URL firmadas caducan y responden 403).
bool debePedirPreviewFresco(ReferenciaMusica referencia) {
  if (!referencia.tienePreview) return true;
  if (referencia.idPistaDeezer == null) return false;
  return referencia.esDeezer ||
      referencia.previewProveedorEfectivo == ProveedorPreviewMusica.deezer;
}

/// True si la URL del preview se puede guardar: nunca si es de Deezer.
bool convienePersistirPreview(ReferenciaMusica referencia) =>
    !referencia.esDeezer &&
    referencia.previewProveedorEfectivo != ProveedorPreviewMusica.deezer;

/// Prepara y carga el preview en streaming.
///
/// Si no hay URL, o la guardada es de Deezer (caduca), la pide por id antes;
/// si una URL guardada de otro origen falla, la vuelve a pedir y reintenta
/// una vez. Lanza [FalloMusica] con [TipoFalloMusica.sinPreview] si no hay
/// clip.
Future<ResultadoCargaPreview> intentarCargarPreviewConRefresco(
  AudioPlayer reproductor,
  ReferenciaMusica referencia,
  RepositorioCatalogoMusica catalogo,
) async {
  var actual = referencia;
  var pedida = false;
  if (debePedirPreviewFresco(actual)) {
    final fresca = await refrescarPreview(actual, catalogo);
    if (fresca == null || !fresca.tienePreview) {
      throw const FalloMusica(TipoFalloMusica.sinPreview);
    }
    actual = fresca;
    pedida = true;
  }
  try {
    await cargarPreviewEnReproductor(reproductor, actual);
    return ResultadoCargaPreview(
      referencia: actual,
      refrescada: pedida && convienePersistirPreview(actual),
    );
  } catch (error, pila) {
    if (pedida) Error.throwWithStackTrace(error, pila);
    final fresca = await refrescarPreview(actual, catalogo);
    if (fresca == null || !fresca.tienePreview) {
      Error.throwWithStackTrace(error, pila);
    }
    await cargarPreviewEnReproductor(reproductor, fresca);
    return ResultadoCargaPreview(
      referencia: fresca,
      refrescada: convienePersistirPreview(fresca),
    );
  }
}
