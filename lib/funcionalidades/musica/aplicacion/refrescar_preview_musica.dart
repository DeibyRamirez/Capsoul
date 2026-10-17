import '../dominio/referencia_musica.dart';
import '../dominio/repositorio_catalogo_musica.dart';

/// Vuelve a resolver `previewUrl` en catálogo (p. ej. enlace caducado en BD).
Future<ReferenciaMusica?> refrescarPreview(
  ReferenciaMusica actual,
  RepositorioCatalogoMusica repositorio,
) async {
  final consulta = '${actual.artista} ${actual.titulo}'.trim();
  if (consulta.isEmpty) return null;
  final resultados = await repositorio.buscar(consulta, limite: 10);
  for (final candidata in resultados) {
    if (candidata.idExterno != actual.idExterno || !candidata.tienePreview) {
      continue;
    }
    return ReferenciaMusica(
      proveedor: actual.proveedor,
      idExterno: actual.idExterno,
      titulo: actual.titulo,
      artista: actual.artista,
      urlCompleta: actual.urlCompleta,
      previewUrl: candidata.previewUrl,
      previewProveedor: candidata.previewProveedor,
      portadaUrl: candidata.portadaUrl ?? actual.portadaUrl,
      uriProfundo: actual.uriProfundo,
      enlaceDeezer: candidata.enlaceDeezer ?? actual.enlaceDeezer,
    );
  }
  return null;
}
