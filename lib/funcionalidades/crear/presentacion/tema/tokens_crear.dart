import 'package:flutter/material.dart';

import '../../../../nucleo/tema/colores_app.dart';

/// Tokens visuales del módulo crear (cámara a pantalla completa).
@immutable
class TokensCrear extends ThemeExtension<TokensCrear> {
  const TokensCrear({
    this.marcaPrimario = ColoresApp.acento,
    this.sobreMarca = ColoresApp.sobrePrimario,
    this.superficieCamara = ColoresApp.sobrePrimario,
    this.superficieCamaraAtenuada = const Color(0xB3FFFFFF),
    this.colorScrim = Colors.black,
    this.opacidadScrimSuperior = 0.45,
    this.opacidadScrimInferior = 0.55,
    this.objetivoTactilMin = 48,
    this.tamanoBotonCaptura = 80,
    this.grosorAnillo = 6,
  });

  final Color marcaPrimario;
  final Color sobreMarca;
  final Color superficieCamara;
  final Color superficieCamaraAtenuada;
  final Color colorScrim;
  final double opacidadScrimSuperior;
  final double opacidadScrimInferior;
  final double objetivoTactilMin;
  final double tamanoBotonCaptura;
  final double grosorAnillo;

  static const TokensCrear claro = TokensCrear();

  @override
  TokensCrear copyWith({
    Color? marcaPrimario,
    Color? sobreMarca,
    Color? superficieCamara,
    Color? superficieCamaraAtenuada,
    Color? colorScrim,
    double? opacidadScrimSuperior,
    double? opacidadScrimInferior,
    double? objetivoTactilMin,
    double? tamanoBotonCaptura,
    double? grosorAnillo,
  }) {
    return TokensCrear(
      marcaPrimario: marcaPrimario ?? this.marcaPrimario,
      sobreMarca: sobreMarca ?? this.sobreMarca,
      superficieCamara: superficieCamara ?? this.superficieCamara,
      superficieCamaraAtenuada:
          superficieCamaraAtenuada ?? this.superficieCamaraAtenuada,
      colorScrim: colorScrim ?? this.colorScrim,
      opacidadScrimSuperior:
          opacidadScrimSuperior ?? this.opacidadScrimSuperior,
      opacidadScrimInferior: opacidadScrimInferior ?? this.opacidadScrimInferior,
      objetivoTactilMin: objetivoTactilMin ?? this.objetivoTactilMin,
      tamanoBotonCaptura: tamanoBotonCaptura ?? this.tamanoBotonCaptura,
      grosorAnillo: grosorAnillo ?? this.grosorAnillo,
    );
  }

  @override
  TokensCrear lerp(ThemeExtension<TokensCrear>? other, double t) {
    if (other is! TokensCrear) return this;
    return TokensCrear(
      marcaPrimario: Color.lerp(marcaPrimario, other.marcaPrimario, t)!,
      sobreMarca: Color.lerp(sobreMarca, other.sobreMarca, t)!,
      superficieCamara: Color.lerp(superficieCamara, other.superficieCamara, t)!,
      superficieCamaraAtenuada:
          Color.lerp(superficieCamaraAtenuada, other.superficieCamaraAtenuada, t)!,
      colorScrim: Color.lerp(colorScrim, other.colorScrim, t)!,
      opacidadScrimSuperior:
          opacidadScrimSuperior + (other.opacidadScrimSuperior - opacidadScrimSuperior) * t,
      opacidadScrimInferior:
          opacidadScrimInferior + (other.opacidadScrimInferior - opacidadScrimInferior) * t,
      objetivoTactilMin: objetivoTactilMin,
      tamanoBotonCaptura: tamanoBotonCaptura,
      grosorAnillo: grosorAnillo,
    );
  }
}

TokensCrear tokensCrearDe(BuildContext context) {
  return Theme.of(context).extension<TokensCrear>() ?? TokensCrear.claro;
}

Duration duracionMotionCrear(BuildContext context, Duration duracion) {
  return MediaQuery.disableAnimationsOf(context) ? Duration.zero : duracion;
}
