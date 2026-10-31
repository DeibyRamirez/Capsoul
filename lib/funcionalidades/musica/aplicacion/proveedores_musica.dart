import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../datos/repositorio_musica_deezer.dart';
import '../dominio/repositorio_catalogo_musica.dart';
import 'abridor_enlaces_musica.dart';
import 'coordinador_preview_musica.dart';

/// Cliente HTTP del catálogo de música (se cierra al liberar el proveedor).
final proveedorClienteHttpMusica = Provider<http.Client>((ref) {
  final cliente = http.Client();
  ref.onDispose(cliente.close);
  return cliente;
});

/// Catálogo de música: API pública de Deezer.
final proveedorRepositorioCatalogoMusica =
    Provider<RepositorioCatalogoMusica>((ref) {
  return RepositorioMusicaDeezer(ref.watch(proveedorClienteHttpMusica));
});

/// Espera tras la última tecla antes de buscar (debounce).
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
