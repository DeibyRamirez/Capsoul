import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../datos/repositorio_musica_con_cache.dart';
import '../datos/repositorio_musica_deezer.dart';
import '../dominio/cache_busquedas_musica.dart';
import '../dominio/repositorio_catalogo_musica.dart';
import 'abridor_enlaces_musica.dart';
import 'coordinador_preview_musica.dart';

/// Cliente HTTP del catálogo de música (se cierra al liberar el proveedor).
final proveedorClienteHttpMusica = Provider<http.Client>((ref) {
  final cliente = http.Client();
  ref.onDispose(cliente.close);
  return cliente;
});

/// Catálogo de música: API pública de Deezer, sin caché.
///
/// La reproducción lo usa para pedir `GET /track/<id>` con un preview fresco.
final proveedorRepositorioCatalogoMusica = Provider<RepositorioCatalogoMusica>((
  ref,
) {
  return RepositorioMusicaDeezer(ref.watch(proveedorClienteHttpMusica));
});

/// Caché en memoria de las búsquedas (15 minutos, 50 consultas).
final proveedorCacheBusquedasMusica = Provider<CacheBusquedasMusica>(
  (ref) => CacheBusquedasMusica(),
);

/// Búsqueda de la pantalla: Deezer, con caché y peticiones duplicadas unidas.
final proveedorRepositorioBusquedaMusica = Provider<RepositorioCatalogoMusica>((
  ref,
) {
  return RepositorioMusicaConCache(
    ref.watch(proveedorRepositorioCatalogoMusica),
    cache: ref.watch(proveedorCacheBusquedasMusica),
  );
});

/// Espera tras la última tecla antes de buscar (antirrebote).
final proveedorEsperaBusquedaMusica = Provider<Duration>(
  (ref) => const Duration(milliseconds: 400),
);

/// Garantiza que solo suene un preview a la vez en toda la app.
final proveedorCoordinadorPreviewMusica = Provider<CoordinadorPreviewMusica>(
  (ref) => CoordinadorPreviewMusica(),
);

/// Abre Deezer, Spotify o YouTube en una app externa.
final proveedorAbridorEnlacesMusica = Provider<AbridorEnlacesMusica>(
  (ref) => const AbridorEnlacesMusica(),
);
