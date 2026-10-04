import 'capsula.dart';
import 'nueva_capsula.dart';

/// Acceso a las cápsulas del usuario. Las implementaciones traducen los
/// errores a [FalloCapsula].
abstract interface class RepositorioCapsulas {
  /// Guarda la cápsula programada con los recuerdos elegidos (ya existen
  /// en `elementos`). Devuelve el id de la cápsula.
  Future<String> crearCapsula(NuevaCapsula nueva);

  /// Cápsulas creadas por el usuario, de la más reciente a la más antigua.
  Future<List<Capsula>> listarMisCapsulas();

  /// Cápsula con sus elementos o `null` si no existe o RLS la oculta.
  Future<Capsula?> obtenerCapsula(String id);
}
