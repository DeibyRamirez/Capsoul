import 'enlace_medio.dart';

/// Entrega segura de medios: URLs firmadas de los recuerdos visibles.
abstract interface class RepositorioUrlsMedio {
  /// URL firmada de la [variante] del medio [publicId] del recuerdo
  /// [idRecuerdo], o `null` si no tiene medio, no se puede ver o la entrega
  /// no está disponible (la UI muestra el respaldo).
  Future<String?> enlace({
    required String idRecuerdo,
    required String publicId,
    required VarianteMedio variante,
  });
}
