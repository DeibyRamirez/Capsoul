import 'package:url_launcher/url_launcher.dart';

import '../dominio/pista_deezer.dart';
import '../dominio/referencia_musica.dart';

/// Firma de `canLaunchUrl` / `launchUrl` (inyectable en pruebas).
typedef FuncionEnlace = Future<bool> Function(Uri uri);

Future<bool> _puedeAbrirPorDefecto(Uri uri) => canLaunchUrl(uri);

Future<bool> _abrirPorDefecto(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);

/// Búsqueda simple en Spotify (sin API de Spotify).
Uri enlaceBusquedaSpotify(String consulta) => Uri.parse(
      'https://open.spotify.com/search/${Uri.encodeComponent(consulta.trim())}',
    );

/// Búsqueda en YouTube (sin YouTube Data API).
Uri enlaceBusquedaYoutube({required String titulo, required String artista}) {
  final consulta = '$artista $titulo'.trim();
  return Uri.https('www.youtube.com', '/results', {'search_query': consulta});
}

/// Búsqueda en YouTube Music (sin API).
Uri enlaceBusquedaYoutubeMusic({
  required String titulo,
  required String artista,
}) {
  final consulta = '$artista $titulo'.trim();
  return Uri.https('music.youtube.com', '/search', {'q': consulta});
}

/// Búsqueda en Deezer cuando no hay id de pista.
Uri enlaceBusquedaDeezer({required String titulo, required String artista}) {
  final consulta = '$artista $titulo'.trim();
  return Uri.parse(
    'https://www.deezer.com/search/${Uri.encodeComponent(consulta)}',
  );
}

/// Enlace web de la pista en Deezer (o búsqueda si no se conoce el id).
Uri enlaceDeezerParaReferencia(ReferenciaMusica referencia) {
  final id = referencia.idPistaDeezer;
  if (id != null) return Uri.parse('https://www.deezer.com/track/$id');
  final directo = referencia.enlaceDeezer?.trim();
  if (directo != null && directo.isNotEmpty) return Uri.parse(directo);
  return enlaceBusquedaDeezer(
    titulo: referencia.titulo,
    artista: referencia.artista,
  );
}

/// Abre la pista en apps externas (Deezer, Spotify, YouTube).
class AbridorEnlacesMusica {
  const AbridorEnlacesMusica({
    this.puedeAbrir = _puedeAbrirPorDefecto,
    this.abrir = _abrirPorDefecto,
  });

  final FuncionEnlace puedeAbrir;
  final FuncionEnlace abrir;

  /// Abre [uri] en una app externa; false si no se pudo.
  Future<bool> abrirExterno(Uri uri) async {
    try {
      return await abrir(uri);
    } catch (_) {
      return false;
    }
  }

  /// Intenta `deezer://www.deezer.com/track/<id>`; si no hay app, la web.
  Future<bool> abrirEnDeezer(ReferenciaMusica referencia) async {
    final id = referencia.idPistaDeezer;
    if (id != null) {
      final profundo = enlaceProfundoDeezer(id);
      try {
        if (await puedeAbrir(profundo) && await abrir(profundo)) {
          return true;
        }
      } catch (_) {
        // Sin app de Deezer: seguimos con el enlace web.
      }
    }
    return abrirExterno(enlaceDeezerParaReferencia(referencia));
  }

  /// Filas antiguas de Spotify abren la pista; el resto, una búsqueda.
  Future<bool> abrirEnSpotify(ReferenciaMusica referencia) async {
    if (referencia.proveedor == ProveedorMusica.spotify) {
      final profundo = referencia.uriProfundo;
      if (profundo != null && profundo.startsWith('spotify:')) {
        try {
          final uri = Uri.parse(profundo);
          if (await puedeAbrir(uri) && await abrir(uri)) return true;
        } catch (_) {
          // Seguimos con la web.
        }
      }
      return abrirExterno(Uri.parse(referencia.urlCompleta));
    }
    return abrirExterno(enlaceBusquedaSpotify(referencia.consultaBusqueda));
  }

  Future<bool> abrirEnYoutube(ReferenciaMusica referencia) => abrirExterno(
        enlaceBusquedaYoutube(
          titulo: referencia.titulo,
          artista: referencia.artista,
        ),
      );

  Future<bool> abrirEnYoutubeMusic(ReferenciaMusica referencia) =>
      abrirExterno(
        enlaceBusquedaYoutubeMusic(
          titulo: referencia.titulo,
          artista: referencia.artista,
        ),
      );
}
