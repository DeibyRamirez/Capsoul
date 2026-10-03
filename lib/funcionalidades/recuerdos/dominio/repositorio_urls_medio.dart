import 'url_medio.dart';

/// Entrega segura de medios: URLs temporales de los recuerdos visibles.
abstract interface class RepositorioUrlsMedio {
  /// URLs del recuerdo [idRecuerdo] o `null` si no tiene medio, no se puede
  /// ver o la entrega no está disponible (la UI muestra el respaldo).
  Future<UrlMedio?> obtener(String idRecuerdo);
}
