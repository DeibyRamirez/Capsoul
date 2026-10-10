import 'package:flutter/material.dart';

import 'colores_app.dart';

/// Degradados de marca reutilizables en fondos de pantalla.
abstract final class DegradadosCapsoul {
  /// Inicio y zonas hero: tinte muy leve arriba → superficie (sin banda blanca al final).
  static const LinearGradient suave = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFEBF0F6),
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
