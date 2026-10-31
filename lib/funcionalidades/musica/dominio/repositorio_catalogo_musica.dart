import 'referencia_musica.dart';

/// Catalogo de musica (API publica de Deezer).
abstract interface class RepositorioCatalogoMusica {
  /// Busca pistas. Lanza `FalloMusica` si la API falla.
  Future<List<ReferenciaMusica>> buscar(
    String consulta, {
    int limite = 25,
    String mercado = 'CO',
  });

  /// Vuelve a pedir la pista por id (preview fresco). Null si ya no existe.
  Future<ReferenciaMusica?> obtenerPorId(String idExterno);
}
