import 'capsula.dart';
import 'nueva_capsula.dart';

/// Acceso a las cápsulas del usuario. Las implementaciones traducen los
/// errores a [FalloCapsula] o [FalloMedios].
abstract interface class RepositorioCapsulas {
  /// Sube los medios, guarda los elementos y la cápsula programada.
  /// [alProgreso] recibe cuántos elementos ya se guardaron de [total].
  /// Devuelve el id de la cápsula.
  Future<String> crearCapsula(
    NuevaCapsula nueva, {
    void Function(int guardados, int total)? alProgreso,
  });

  /// Cápsulas creadas por el usuario, de la más reciente a la más antigua.
  Future<List<Capsula>> listarMisCapsulas();

  /// Cápsula con sus elementos o `null` si no existe o RLS la oculta.
  Future<Capsula?> obtenerCapsula(String id);
}
