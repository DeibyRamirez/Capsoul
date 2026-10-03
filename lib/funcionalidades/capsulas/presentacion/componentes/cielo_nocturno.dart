import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../nucleo/tema/colores_app.dart';

/// Fondo nocturno de la cabecera: degradado de marca con estrellas y
/// linternas flotantes (placeholder elegante, sin imágenes externas).
class CieloNocturno extends StatelessWidget {
  const CieloNocturno({super.key, this.brillo = 1, this.child});

  final double brillo;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [ColoresApp.primario, ColoresApp.primario, ColoresApp.acento],
          stops: [0, 0.55, 1],
        ),
      ),
      child: CustomPaint(
        painter: _PintorCielo(brillo: brillo),
        child: child,
      ),
    );
  }
}

class _PintorCielo extends CustomPainter {
  _PintorCielo({required this.brillo});

  final double brillo;

  @override
  void paint(Canvas canvas, Size size) {
    final aleatorio = math.Random(11);
    final estrella = Paint();
    for (var i = 0; i < 40; i++) {
      final punto = Offset(
        aleatorio.nextDouble() * size.width,
        aleatorio.nextDouble() * size.height * 0.7,
      );
      estrella.color = ColoresApp.sobrePrimario
          .withValues(alpha: (0.2 + 0.5 * aleatorio.nextDouble()) * brillo);
      canvas.drawCircle(punto, 0.6 + aleatorio.nextDouble() * 1.2, estrella);
    }
    for (var i = 0; i < 9; i++) {
      final centro = Offset(
        aleatorio.nextDouble() * size.width,
        size.height * (0.05 + 0.6 * aleatorio.nextDouble()),
      );
      final ancho = 5 + aleatorio.nextDouble() * 6;
      final halo = Paint()
        ..shader = RadialGradient(
          colors: [
            ColoresApp.sobrePrimario.withValues(alpha: 0.35 * brillo),
            ColoresApp.sobrePrimario.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: centro, radius: ancho * 2.4));
      canvas.drawCircle(centro, ancho * 2.4, halo);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: centro, width: ancho, height: ancho * 1.3),
          Radius.circular(ancho * 0.3),
        ),
        Paint()
          ..color = ColoresApp.sobrePrimario.withValues(alpha: 0.75 * brillo),
      );
    }
  }

  @override
  bool shouldRepaint(_PintorCielo anterior) => anterior.brillo != brillo;
}
