import 'package:flutter/material.dart';

import 'colores_app.dart';

/// Degradados de marca reutilizables en fondos de pantalla.
abstract final class DegradadosCapsoul {
  /// Fondo claro por defecto: azul hielo arriba, casi blanco abajo.
  static const LinearGradient suave = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [ColoresApp.fondoInicio, ColoresApp.fondoFin],
  );

  /// Cielo nocturno (banners con luciernagas): medianoche a azul real.
  static const LinearGradient nocturno = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [ColoresApp.medianoche, ColoresApp.medianoche, ColoresApp.primario],
    stops: [0, 0.55, 1],
  );

  /// Banner horizontal oscuro (frase de Inicio).
  static const LinearGradient banner = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [ColoresApp.medianoche, ColoresApp.primario],
  );
}
