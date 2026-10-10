import 'referencia_musica.dart';

/// Búsqueda de pistas en el catálogo (proxy Spotify en el servidor).
abstract interface class RepositorioCatalogoMusica {
  Future<List<ReferenciaMusica>> buscar(
    String consulta, {
    int limite = 10,
    String mercado = 'CO',
  });
}
