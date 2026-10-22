import 'package:flutter/material.dart';

import 'colores_app.dart';

/// Escala tipográfica: Playfair en titulares editoriales, Poppins en la UI.
///
/// Las familias se escriben aquí (no se importa [TemaApp]) para no crear un
/// ciclo con el tema Material.
abstract final class TipografiaApp {
  static const String fuenteUi = 'Poppins';
  static const String fuenteTitulos = 'PlayfairDisplay';

  static const TextStyle display = TextStyle(
    fontFamily: fuenteTitulos,
    fontSize: 32,
    fontWeight: FontWeight.w600,
    height: 1.15,
    color: ColoresApp.textoPrincipal,
  );

  static const TextStyle displayCompacto = TextStyle(
    fontFamily: fuenteTitulos,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: ColoresApp.textoPrincipal,
  );

  static const TextStyle titular = TextStyle(
    fontFamily: fuenteTitulos,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.25,
    color: ColoresApp.primario,
  );

  static const TextStyle titulo = TextStyle(
    fontFamily: fuenteUi,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: ColoresApp.textoPrincipal,
  );

  static const TextStyle tituloPequeno = TextStyle(
    fontFamily: fuenteUi,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.35,
    color: ColoresApp.textoPrincipal,
  );

  static const TextStyle cuerpo = TextStyle(
    fontFamily: fuenteUi,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: ColoresApp.textoPrincipal,
  );

  static const TextStyle cuerpoPequeno = TextStyle(
    fontFamily: fuenteUi,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: ColoresApp.textoSecundario,
  );

  static const TextStyle etiqueta = TextStyle(
    fontFamily: fuenteUi,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.3,
    color: ColoresApp.textoPrincipal,
  );

  static const TextStyle etiquetaPequena = TextStyle(
    fontFamily: fuenteUi,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.3,
    color: ColoresApp.textoSecundario,
  );

  /// Aplica la escala sobre el [TextTheme] base de Material.
  static TextTheme aplicar(TextTheme base) {
    return base.copyWith(
      displayLarge: display,
      displayMedium: displayCompacto,
      headlineMedium: titular,
      titleLarge: titulo,
      titleMedium: tituloPequeno,
      titleSmall: tituloPequeno.copyWith(fontSize: 14),
      bodyLarge: cuerpo,
      bodyMedium: cuerpoPequeno.copyWith(color: ColoresApp.textoPrincipal),
      bodySmall: cuerpoPequeno.copyWith(fontSize: 12),
      labelLarge: etiqueta,
      labelMedium: etiquetaPequena,
      labelSmall: etiquetaPequena.copyWith(fontWeight: FontWeight.w400),
    );
  }
}
