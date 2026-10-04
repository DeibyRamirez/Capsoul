import 'package:flutter/material.dart';

import 'colores_app.dart';

/// Degradados de marca reutilizables en fondos de pantalla.
abstract final class DegradadosCapsoul {
  /// Inicio, tabs y listas: acento tenue arriba → superficie.
  static const LinearGradient suave = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x2E3D6B9A), // acento @ 18%
      ColoresApp.superficie,
    ],
  );

  /// Cabeceras hero y autenticación: cielo nocturno.
  static const LinearGradient nocturno = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [ColoresApp.primario, ColoresApp.primario, ColoresApp.acento],
    stops: [0, 0.55, 1],
  );
}
