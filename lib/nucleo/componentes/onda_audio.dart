import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Barras verticales de una onda de audio. Con [muestras] vacías dibuja una
/// onda decorativa estable a partir de [semilla].
class OndaAudio extends StatelessWidget {
  const OndaAudio({
    super.key,
    required this.color,
    this.muestras = const [],
    this.semilla = 0,
    this.barras = 32,
    this.altura = 48,
    this.progreso,
    this.colorProgreso,
  });

  final Color color;
  final List<double> muestras;
  final int semilla;
  final int barras;
  final double altura;

  /// Si se indica (0..1), pinta con [colorProgreso] las barras ya recorridas.
  final double? progreso;
  final Color? colorProgreso;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: altura,
      width: double.infinity,
      child: CustomPaint(
        painter: _PintorOnda(
          niveles: _niveles(),
          color: color,
          progreso: progreso,
          colorProgreso: colorProgreso ?? color,
        ),
      ),
    );
  }

  List<double> _niveles() {
    if (muestras.isNotEmpty) {
      final ultimas = muestras.length > barras
          ? muestras.sublist(muestras.length - barras)
          : muestras;
      return ultimas;
    }
    final aleatorio = math.Random(semilla);
    return List.generate(
      barras,
      (i) => 0.25 + 0.75 * (0.5 + 0.5 * math.sin(i * 0.7 + semilla)) *
          (0.6 + 0.4 * aleatorio.nextDouble()),
    );
  }
}

class _PintorOnda extends CustomPainter {
  _PintorOnda({
    required this.niveles,
    required this.color,
    required this.progreso,
    required this.colorProgreso,
  });

  final List<double> niveles;
  final Color color;
  final double? progreso;
  final Color colorProgreso;

  @override
  void paint(Canvas canvas, Size size) {
    if (niveles.isEmpty) return;
    final paso = size.width / niveles.length;
    final ancho = math.max(2.0, paso * 0.55);
    final pincel = Paint()..strokeCap = StrokeCap.round;
    for (var i = 0; i < niveles.length; i++) {
      final nivel = niveles[i].clamp(0.08, 1.0);
      final alto = size.height * nivel;
      final x = paso * i + paso / 2;
      final recorrida = progreso != null && i / niveles.length <= progreso!;
      pincel
        ..color = recorrida ? colorProgreso : color
        ..strokeWidth = ancho;
      canvas.drawLine(
        Offset(x, (size.height - alto) / 2),
        Offset(x, (size.height + alto) / 2),
        pincel,
      );
    }
  }

  @override
  bool shouldRepaint(_PintorOnda anterior) =>
      anterior.niveles != niveles ||
      anterior.color != color ||
      anterior.progreso != progreso;
}
