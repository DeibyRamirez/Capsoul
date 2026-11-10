import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Anillo de progreso 0..1 alrededor del botón de captura.
class AnilloProgresoGrabacion extends StatelessWidget {
  const AnilloProgresoGrabacion({
    super.key,
    required this.progreso,
    required this.color,
    this.grosor = 6,
  });

  final double progreso;
  final Color color;
  final double grosor;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PintorAnillo(progreso.clamp(0, 1), color, grosor),
      child: const SizedBox.expand(),
    );
  }
}

class _PintorAnillo extends CustomPainter {
  _PintorAnillo(this.progreso, this.color, this.grosor);

  final double progreso;
  final Color color;
  final double grosor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
  final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = grosor
      ..color = Colors.white70;
    canvas.drawArc(rect.deflate(grosor / 2), 0, 2 * math.pi, false, base);
    if (progreso > 0) {
      canvas.drawArc(
        rect.deflate(grosor / 2),
        -math.pi / 2,
        2 * math.pi * progreso,
        false,
        base
          ..color = color
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_PintorAnillo anterior) {
    return anterior.progreso != progreso || anterior.color != color;
  }
}
