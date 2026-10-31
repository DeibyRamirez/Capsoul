import '../dominio/referencia_musica.dart';
import '../dominio/repositorio_catalogo_musica.dart';

/// Pide de nuevo el preview (la URL de Deezer caduca).
///
/// - Si se conoce el id de Deezer: `GET /track/<id>`.
/// - Filas antiguas sin id de Deezer: busca por artista y título.
Future<ReferenciaMusica?> refrescarPreview(
  ReferenciaMusica actual,
  RepositorioCatalogoMusica repositorio,
) async {
  final idDeezer = actual.idPistaDeezer;
  if (idDeezer != null) {
    final fresca = await repositorio.obtenerPorId(idDeezer);
    if (fresca == null) return null;
    if (actual.esDeezer) return fresca;
    return actual.copiarConPreview(
      previewUrl: fresca.previewUrl,
      previewProveedor: fresca.previewProveedor,
      portadaUrl: fresca.portadaUrl,
      enlaceDeezer: fresca.enlaceDeezer,
    );
  }
  final consulta = actual.consultaBusqueda;
  if (consulta.isEmpty) return null;
  final resultados = await repositorio.buscar(consulta, limite: 10);
  final titulo = _normalizar(actual.titulo);
  for (final candidata in resultados) {
    if (!candidata.tienePreview) continue;
    final coincide = candidata.idExterno == actual.idExterno ||
        _normalizar(candidata.titulo) == titulo;
    if (!coincide) continue;
    return actual.copiarConPreview(
      previewUrl: candidata.previewUrl,
      previewProveedor: candidata.previewProveedorEfectivo,
      portadaUrl: candidata.portadaUrl,
      enlaceDeezer: candidata.enlaceDeezer,
    );
  }
  return null;
}

String _normalizar(String texto) => texto.trim().toLowerCase();
