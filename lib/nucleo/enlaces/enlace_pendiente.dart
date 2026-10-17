import 'package:flutter/foundation.dart';

/// Destino guardado cuando el usuario abre un enlace sin sesión.
@immutable
sealed class EnlacePendiente {
  const EnlacePendiente();
}

class EnlacePendienteCapsula extends EnlacePendiente {
  const EnlacePendienteCapsula(this.idCapsula);
  final String idCapsula;
}

class EnlacePendienteAmistad extends EnlacePendiente {
  const EnlacePendienteAmistad(this.token);
  final String token;
}
