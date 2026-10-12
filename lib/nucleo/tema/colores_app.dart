import 'package:flutter/material.dart';

/// Colores de marca de Capsoul (modo claro, paleta pastel azul/gris).
/// Los widgets de las funcionalidades deben usar estos valores; nunca
/// hexadecimales escritos a mano.
abstract final class ColoresApp {
  /// Azul real profundo: botones, navegacion activa, logo, bordes.
  static const Color primario = Color(0xFF1B316B);

  /// Azul medio para enlaces, foco e indicadores.
  static const Color acento = Color(0xFF3D6B9A);

  /// Fondo plano por defecto (final del degradado claro).
  static const Color superficie = Color(0xFFF4F8FC);

  /// Campos y tarjetas sobre [superficie].
  static const Color tarjeta = Color(0xFFFFFFFF);
  static const Color sobrePrimario = Color(0xFFFFFFFF);

  /// Texto principal (azul marino oscuro).
  static const Color sobreSuperficie = Color(0xFF111E38);
  static const Color textoPrincipal = Color(0xFF111E38);

  /// Texto secundario (gris azulado): subtitulos y metadatos.
  static const Color atenuado = Color(0xFF5A6E94);
  static const Color textoSecundario = Color(0xFF5A6E94);

  /// Degradado claro de fondo.
  static const Color fondoInicio = Color(0xFFE2EDF8);
  static const Color fondoFin = Color(0xFFF4F8FC);

  /// Borde sutil de tarjetas (1 px).
  static const Color bordeTarjeta = Color(0xFFD6E4F0);

  /// Sombra de tarjeta: azul real al 8 %.
  static const Color sombraTarjeta = Color(0x141B316B);

  /// Iconos inactivos de la barra de navegacion.
  static const Color navInactivo = Color(0xFF8FA1C2);

  /// Dorado calido: solo brillos, estrellas e iconos (no texto).
  static const Color dorado = Color(0xFFF59E0B);
  static const Color doradoClaro = Color(0xFFFDE68A);

  /// Azul medianoche: banners oscuros y cielo con luciernagas.
  static const Color medianoche = Color(0xFF132247);

  /// Colores semanticos de marcas externas (musica).
  static const Color spotify = Color(0xFF1DB954);
  static const Color appleMusic = Color(0xFFA238FF);
  static const Color youtube = Color(0xFFFF0000);

  /// Pasteles para insignias del perfil.
  static const Color pastelAzul = Color(0xFFB8D4E8);
  static const Color pastelVerde = Color(0xFFC8E6C9);
  static const Color pastelRosa = Color(0xFFF8BBD0);

  /// Sombra suave para texto sobre el cielo oscuro.
  static const Color sombraTexto = Color(0x40000000);

  static const Color vidrioCupula = Color(0x33FFFFFF);
  static const Color bordeCupula = Color(0x66FFFFFF);
}
