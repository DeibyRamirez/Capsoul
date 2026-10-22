import 'package:flutter/animation.dart';

/// Duraciones y curvas compartidas. El movimiento es lento y calmado.
abstract final class MovimientoApp {
  static const Duration rapido = Duration(milliseconds: 200);
  static const Duration medio = Duration(milliseconds: 350);
  static const Duration lento = Duration(milliseconds: 700);

  static const Curve curva = Curves.easeOutCubic;
  static const Curve entrada = Curves.easeOutCubic;
  static const Curve salida = Curves.easeInCubic;
}
