import 'package:flutter/material.dart';

import 'colores_app.dart';

/// Tema Material 3 de Capsoul: modo claro, Poppins en la UI y Playfair
/// Display en titulos de marca.
abstract final class TemaApp {
  static const double radioPequeno = 12;
  static const double radioMediano = 16;
  static const double radioGrande = 20;

  /// Botones tipo pildora.
  static const double radioPildora = 30;

  /// Alto estandar de botones.
  static const double altoBoton = 48;

  /// Familia de la UI (assets/fonts).
  static const String fuenteUi = 'Poppins';

  /// Familia de titulos de marca / hero (assets/fonts).
  static const String fuenteTitulos = 'PlayfairDisplay';

  /// Sombra de tarjeta (azul real al 8 %).
  static const List<BoxShadow> sombraTarjeta = [
    BoxShadow(
      color: ColoresApp.sombraTarjeta,
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];

  /// Decoracion estandar de tarjeta blanca con borde y sombra.
  static BoxDecoration decoracionTarjeta({double radio = radioGrande}) =>
      BoxDecoration(
        color: ColoresApp.tarjeta,
        borderRadius: BorderRadius.circular(radio),
        border: Border.all(color: ColoresApp.bordeTarjeta),
        boxShadow: sombraTarjeta,
      );

  static ThemeData get claro {
    final esquemaColores = ColorScheme.fromSeed(
      seedColor: ColoresApp.primario,
      primary: ColoresApp.primario,
      onPrimary: ColoresApp.sobrePrimario,
      secondary: ColoresApp.acento,
      tertiary: ColoresApp.dorado,
      surface: ColoresApp.superficie,
      onSurface: ColoresApp.textoPrincipal,
      onSurfaceVariant: ColoresApp.textoSecundario,
      outline: ColoresApp.bordeTarjeta,
      outlineVariant: ColoresApp.bordeTarjeta,
      brightness: Brightness.light,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: fuenteUi,
    );
    final textoBase = base.textTheme.apply(
      fontFamily: fuenteUi,
      bodyColor: ColoresApp.textoPrincipal,
      displayColor: ColoresApp.textoPrincipal,
    );
    final temaTexto = textoBase.copyWith(
      titleMedium: textoBase.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      titleSmall: textoBase.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      labelLarge: textoBase.labelLarge?.copyWith(fontWeight: FontWeight.w500),
    );

    final bordeCampo = OutlineInputBorder(
      borderRadius: BorderRadius.circular(radioPequeno),
      borderSide: const BorderSide(color: ColoresApp.bordeTarjeta),
    );
    const formaPildora = StadiumBorder();
    const textoBoton = TextStyle(
      fontFamily: fuenteUi,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    );

    return base.copyWith(
      colorScheme: esquemaColores,
      textTheme: temaTexto,
      scaffoldBackgroundColor: ColoresApp.superficie,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: ColoresApp.textoPrincipal,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: temaTexto.titleMedium?.copyWith(
          color: ColoresApp.tarjeta,
          fontWeight: FontWeight.w600,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: ColoresApp.tarjeta,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: ColoresApp.sombraTarjeta,
        indicatorColor: ColoresApp.primario.withValues(alpha: 0.10),
        labelTextStyle: WidgetStateProperty.resolveWith((estados) {
          final seleccionado = estados.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: fuenteUi,
            fontSize: 12,
            fontWeight: seleccionado ? FontWeight.w600 : FontWeight.w400,
            color: seleccionado ? ColoresApp.primario : ColoresApp.navInactivo,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((estados) {
          final seleccionado = estados.contains(WidgetState.selected);
          return IconThemeData(
            color: seleccionado ? ColoresApp.primario : ColoresApp.navInactivo,
            size: 24,
          );
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColoresApp.primario,
          foregroundColor: ColoresApp.sobrePrimario,
          minimumSize: const Size(64, altoBoton),
          textStyle: textoBoton,
          shape: formaPildora,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ColoresApp.primario,
          foregroundColor: ColoresApp.sobrePrimario,
          minimumSize: const Size.fromHeight(altoBoton),
          textStyle: textoBoton,
          shape: formaPildora,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ColoresApp.primario,
          minimumSize: const Size.fromHeight(altoBoton),
          textStyle: textoBoton,
          side: const BorderSide(color: ColoresApp.primario),
          shape: formaPildora,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ColoresApp.acento,
          minimumSize: const Size(48, 48),
          textStyle: textoBoton.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ColoresApp.tarjeta,
        hintStyle: const TextStyle(color: ColoresApp.navInactivo),
        labelStyle: const TextStyle(color: ColoresApp.textoSecundario),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: bordeCampo,
        enabledBorder: bordeCampo,
        focusedBorder: bordeCampo.copyWith(
          borderSide: const BorderSide(color: ColoresApp.acento, width: 1.5),
        ),
        errorBorder: bordeCampo.copyWith(
          borderSide: BorderSide(color: esquemaColores.error),
        ),
        focusedErrorBorder: bordeCampo.copyWith(
          borderSide: BorderSide(color: esquemaColores.error, width: 1.5),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ColoresApp.textoPrincipal,
        contentTextStyle: const TextStyle(
          fontFamily: fuenteUi,
          color: ColoresApp.sobrePrimario,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radioPequeno),
        ),
      ),
      cardTheme: CardThemeData(
        color: ColoresApp.tarjeta,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radioGrande),
          side: const BorderSide(color: ColoresApp.bordeTarjeta),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: ColoresApp.tarjeta,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radioGrande),
        ),
        titleTextStyle: temaTexto.titleLarge?.copyWith(
          color: ColoresApp.textoPrincipal,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: temaTexto.bodyMedium?.copyWith(
          color: ColoresApp.textoSecundario,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: ColoresApp.tarjeta,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(radioGrande),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: ColoresApp.tarjeta,
        selectedColor: ColoresApp.primario.withValues(alpha: 0.12),
        side: const BorderSide(color: ColoresApp.bordeTarjeta),
        labelStyle: const TextStyle(
          fontFamily: fuenteUi,
          color: ColoresApp.textoPrincipal,
          fontSize: 13,
        ),
        shape: const StadiumBorder(),
      ),
      dividerTheme: const DividerThemeData(color: ColoresApp.bordeTarjeta),
      iconTheme: const IconThemeData(color: ColoresApp.primario),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: ColoresApp.primario,
        foregroundColor: ColoresApp.sobrePrimario,
        shape: CircleBorder(),
      ),
    );
  }
}
