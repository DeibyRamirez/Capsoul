import 'package:flutter/material.dart';

import 'colores_app.dart';

/// Tema Material 3 de Capsoul (radios de 12 a 20).
abstract final class TemaApp {
  static const double radioPequeno = 12;
  static const double radioMediano = 16;
  static const double radioGrande = 20;

  static ThemeData get claro {
    final esquemaColores = ColorScheme.fromSeed(
      seedColor: ColoresApp.primario,
      primary: ColoresApp.primario,
      secondary: ColoresApp.acento,
      surface: ColoresApp.superficie,
      brightness: Brightness.light,
    );

    final bordeCampo = OutlineInputBorder(
      borderRadius: BorderRadius.circular(radioPequeno),
      borderSide: BorderSide(color: ColoresApp.atenuado.withValues(alpha: 0.3)),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: esquemaColores,
      scaffoldBackgroundColor: ColoresApp.superficie,
      appBarTheme: const AppBarTheme(
        backgroundColor: ColoresApp.primario,
        foregroundColor: ColoresApp.sobrePrimario,
        elevation: 0,
        centerTitle: true,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: ColoresApp.sobrePrimario,
        indicatorColor: ColoresApp.acento.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((estados) {
          final seleccionado = estados.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: seleccionado ? FontWeight.w600 : FontWeight.w400,
            color: seleccionado ? ColoresApp.primario : ColoresApp.atenuado,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((estados) {
          final seleccionado = estados.contains(WidgetState.selected);
          return IconThemeData(
            color: seleccionado ? ColoresApp.primario : ColoresApp.atenuado,
            size: 24,
          );
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColoresApp.primario,
          foregroundColor: ColoresApp.sobrePrimario,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radioMediano),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ColoresApp.primario,
          foregroundColor: ColoresApp.sobrePrimario,
          minimumSize: const Size.fromHeight(48),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radioMediano),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ColoresApp.primario,
          minimumSize: const Size.fromHeight(48),
          side: const BorderSide(color: ColoresApp.primario),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radioMediano),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ColoresApp.acento,
          minimumSize: const Size(48, 48),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ColoresApp.sobrePrimario,
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
        backgroundColor: ColoresApp.primario,
        contentTextStyle: const TextStyle(color: ColoresApp.sobrePrimario),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radioPequeno),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radioMediano),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: ColoresApp.acento,
        foregroundColor: ColoresApp.sobrePrimario,
      ),
    );
  }
}
