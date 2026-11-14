import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Anillo de progreso 0..1 alrededor del botón de captura.
///
/// Se dibuja dentro de sus límites (el trazo se desplaza medio grosor hacia
/// adentro), así que nunca se corta en los bordes.
class AnilloProgresoGrabacion extends StatelessWidget {
  const AnilloProgresoGrabacion({
    super.key,
    required this.progreso,
    required this.color,
    this.colorPista = Colors.white70,
    this.grosor = 6,
  });

  final double progreso;
  final Color color;
  final Color colorPista;
  final double grosor;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PintorAnillo(progreso.clamp(0, 1), color, colorPista, grosor),
      child: const SizedBox.expand(),
    );
  }
}

class _PintorAnillo extends CustomPainter {
  _PintorAnillo(this.progreso, this.color, this.colorPista, this.grosor);

  final double progreso;
  final Color color;
  final Color colorPista;
  final double grosor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(grosor / 2);
    final pista = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = grosor
      ..color = colorPista;
    canvas.drawArc(rect, 0, 2 * math.pi, false, pista);
    if (progreso > 0) {
      final avance = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = grosor
        ..strokeCap = StrokeCap.round
        ..color = color;
      canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progreso, false, avance);
    }
  }

  @override
  bool shouldRepaint(_PintorAnillo anterior) {
    return anterior.progreso != progreso ||
        anterior.color != color ||
        anterior.colorPista != colorPista ||
        anterior.grosor != grosor;
  }
}