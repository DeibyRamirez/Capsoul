import 'package:url_launcher/url_launcher.dart';

import '../dominio/referencia_musica.dart';
import 'abrir_spotify.dart';

/// Búsqueda en YouTube (sin YouTube Data API).
Uri enlaceBusquedaYoutube({required String titulo, required String artista}) {
  final consulta = '$artista $titulo'.trim();
  return Uri.https(
    'www.youtube.com',
    '/results',
    {'search_query': consulta},
  );
}

/// Búsqueda en Deezer cuando no hay enlace a pista.
Uri enlaceBusquedaDeezer({required String titulo, required String artista}) {
  final consulta = '$artista $titulo'.trim();
  return Uri.parse(
    'https://www.deezer.com/search/${Uri.encodeComponent(consulta)}',
  );
}

Uri enlaceDeezerParaReferencia(ReferenciaMusica referencia) {
  final directo = referencia.enlaceDeezer?.trim();
  if (directo != null && directo.isNotEmpty) {
    return Uri.parse(directo);
  }
  return enlaceBusquedaDeezer(
    titulo: referencia.titulo,
    artista: referencia.artista,
  );
}

Future<bool> abrirUriExterna(Uri uri) async {
  if (!await canLaunchUrl(uri)) return false;
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

Future<bool> abrirEnYoutube({
  required String titulo,
  required String artista,
}) =>
    abrirUriExterna(enlaceBusquedaYoutube(titulo: titulo, artista: artista));

Future<bool> abrirEnDeezer(ReferenciaMusica referencia) =>
    abrirUriExterna(enlaceDeezerParaReferencia(referencia));

Future<bool> abrirEnSpotifyDesdeReferencia(ReferenciaMusica referencia) =>
    abrirEnSpotify(
      urlCompleta: referencia.urlCompleta,
      uriProfundo: referencia.uriProfundo,
    );
