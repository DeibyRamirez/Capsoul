import 'package:flutter/foundation.dart';

/// Flags de UI para desarrollo y QA.
abstract final class FlagsUi {
  /// Muestra bytes, dimensiones y otros metadatos técnicos en captura y detalle.
  static const bool mostrarMetricasElemento = bool.fromEnvironment(
    'MOSTRAR_METRICAS_ELEMENTO',
    defaultValue: kDebugMode,
  );
}
