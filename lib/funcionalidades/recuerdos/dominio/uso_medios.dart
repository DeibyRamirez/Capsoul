import 'package:flutter/foundation.dart';

import '../../elementos/dominio/limites_medios.dart';

/// Espacio ocupado por los medios del usuario (RPC `mi_uso_medios`).
@immutable
class UsoMedios {
  const UsoMedios({
    required this.bytesUsados,
    this.bytesLimite = LimitesMedios.cuotaBytesPorUsuario,
  });

  final int bytesUsados;
  final int bytesLimite;

  /// Fracción usada entre 0 y 1.
  double get fraccion =>
      bytesLimite <= 0 ? 0 : (bytesUsados / bytesLimite).clamp(0.0, 1.0);

  @override
  bool operator ==(Object other) =>
      other is UsoMedios &&
      other.bytesUsados == bytesUsados &&
      other.bytesLimite == bytesLimite;

  @override
  int get hashCode => Object.hash(bytesUsados, bytesLimite);
}
