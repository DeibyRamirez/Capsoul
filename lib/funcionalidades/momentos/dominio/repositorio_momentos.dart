import 'momento.dart';
import 'nuevo_momento.dart';

/// Momentos del usuario. Las implementaciones traducen los errores a
/// [FalloMomento].
abstract interface class RepositorioMomentos {
  /// Guarda el momento con sus recuerdos y portada. Devuelve su id.
  Future<String> crear(NuevoMomento nuevo);

  /// Momentos propios, del más reciente al más antiguo (con portada y
  /// cantidad, sin la lista de recuerdos).
  Future<List<Momento>> listar();

  /// Momento con sus recuerdos ordenados o `null`.
  Future<Momento?> obtener(String id);

  Future<void> eliminar(String id);
}
