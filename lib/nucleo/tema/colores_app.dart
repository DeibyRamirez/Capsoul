import 'package:flutter/material.dart';

/// Colores de marca de Capsoul. Los widgets de las funcionalidades deben usar
/// estos valores; nunca hexadecimales escritos a mano.
abstract final class ColoresApp {
  static const Color primario = Color(0xFF1B2A4A);
  static const Color acento = Color(0xFF3D6B9A);
  static const Color superficie = Color(0xFFF5F7FA);
  /// Campos y tarjetas sobre [superficie] (contraste sutil, sin depender del degradado).
  static const Color tarjeta = Color(0xFFFFFFFF);
  static const Color sobrePrimario = Color(0xFFFFFFFF);
  static const Color sobreSuperficie = Color(0xFF1A1A2E);
  static const Color atenuado = Color(0xFF6B7280);
  static const Color vidrioCupula = Color(0x33FFFFFF);
  static const Color bordeCupula = Color(0x66FFFFFF);
}
