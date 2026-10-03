import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tema/colores_app.dart';

/// Frasco de vidrio de Capsoul (la cápsula): cuerpo de vidrio, tapa y luces
/// interiores. [brillo] (0..1) enciende las luces y [aperturaTapa] (0..1)
/// levanta la tapa; así se reutiliza en Inicio, el detalle y la animación de
/// apertura. Solo usa colores de [ColoresApp].
class FrascoLuminoso extends StatelessWidget {
  const FrascoLuminoso({
    super.key,
    this.tamano = 200,
    this.brillo = 0.7,
    this.aperturaTapa = 0,
    this.conRecuerdos = false,
    this.conCandado = false,
  });

  final double tamano;
  final double brillo;
  final double aperturaTapa;

  /// Dibuja "fotos" dentro del frasco (visual de Inicio).
  final bool conRecuerdos;

  /// Dibuja un candado en la base (cápsula sellada).
  final bool conCandado;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: tamano * 0.8,
      height: tamano,
      child: CustomPaint(
        painter: _PintorFrasco(
          brillo: brillo.clamp(0, 1),
          aperturaTapa: aperturaTapa.clamp(0, 1),
          conRecuerdos: conRecuerdos,
          conCandado: conCandado,
        ),
      ),
    );
  }
}

class _PintorFrasco extends CustomPainter {
  _PintorFrasco({
    required this.brillo,
    required this.aperturaTapa,
    required this.conRecuerdos,
    required this.conCandado,
  });

  final double brillo;
  final double aperturaTapa;
  final bool conRecuerdos;
  final bool conCandado;

  static const LinearGradient _degradadoMarino = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [ColoresApp.acento, ColoresApp.primario],
  );

  @override
  void paint(Canvas canvas, Size size) {
    final ancho = size.width;
    final alto = size.height;
    final cuerpo = RRect.fromRectAndRadius(
      Rect.fromLTWH(ancho * 0.08, alto * 0.22, ancho * 0.84, alto * 0.7),
      Radius.circular(ancho * 0.22),
    );

    // Halo exterior.
    final halo = Paint()
      ..shader = RadialGradient(
        colors: [
          ColoresApp.sobrePrimario.withValues(alpha: 0.55 * brillo),
          ColoresApp.acento.withValues(alpha: 0.18 * brillo),
          ColoresApp.acento.withValues(alpha: 0),
        ],
        stops: const [0, 0.55, 1],
      ).createShader(
        Rect.fromCircle(center: cuerpo.center, radius: alto * 0.62),
      );
    canvas.drawCircle(cuerpo.center, alto * 0.62, halo);

    // Vidrio.
    final vidrio = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          ColoresApp.sobrePrimario.withValues(alpha: 0.45),
          ColoresApp.acento.withValues(alpha: 0.35),
          ColoresApp.primario.withValues(alpha: 0.55),
        ],
      ).createShader(cuerpo.outerRect);
    canvas.drawRRect(cuerpo, vidrio);

    if (conRecuerdos) _pintarRecuerdos(canvas, cuerpo.outerRect);
    _pintarLuces(canvas, cuerpo.outerRect);

    // Reflejo del vidrio.
    final reflejo = Paint()
      ..color = ColoresApp.sobrePrimario.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = ancho * 0.035;
    canvas.drawArc(
      cuerpo.outerRect.deflate(ancho * 0.08),
      math.pi * 1.05,
      math.pi * 0.35,
      false,
      reflejo,
    );
    final borde = Paint()
      ..color = ColoresApp.bordeCupula
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(cuerpo, borde);

    _pintarTapa(canvas, size);
    if (conCandado) _pintarCandado(canvas, cuerpo.outerRect);
  }

  void _pintarLuces(Canvas canvas, Rect area) {
    if (brillo <= 0) return;
    final aleatorio = math.Random(7);
    for (var i = 0; i < 16; i++) {
      final centro = Offset(
        area.left + area.width * (0.15 + 0.7 * aleatorio.nextDouble()),
        area.top + area.height * (0.12 + 0.78 * aleatorio.nextDouble()),
      );
      final radio = area.width * (0.015 + 0.02 * aleatorio.nextDouble());
      final luz = Paint()
        ..shader = RadialGradient(
          colors: [
            ColoresApp.sobrePrimario.withValues(alpha: brillo),
            ColoresApp.sobrePrimario.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: centro, radius: radio * 3));
      canvas.drawCircle(centro, radio * 3, luz);
    }
  }

  void _pintarRecuerdos(Canvas canvas, Rect area) {
    final fotos = [
      (dx: 0.18, dy: 0.18, angulo: -0.18),
      (dx: 0.46, dy: 0.42, angulo: 0.12),
      (dx: 0.22, dy: 0.58, angulo: -0.06),
    ];
    for (final foto in fotos) {
      canvas.save();
      final origen = Offset(
        area.left + area.width * foto.dx,
        area.top + area.height * foto.dy,
      );
      canvas.translate(origen.dx, origen.dy);
      canvas.rotate(foto.angulo);
      final marco = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, area.width * 0.36, area.width * 0.3),
        const Radius.circular(4),
      );
      canvas.drawRRect(
        marco,
        Paint()..color = ColoresApp.sobrePrimario.withValues(alpha: 0.92),
      );
      final interior = marco.deflate(area.width * 0.025);
      canvas.drawRRect(
        interior,
        Paint()
          ..shader = _degradadoMarino.createShader(interior.outerRect),
      );
      canvas.restore();
    }
  }

  void _pintarTapa(Canvas canvas, Size size) {
    final ancho = size.width;
    final alto = size.height;
    final elevacion = alto * 0.16 * aperturaTapa;
    canvas.save();
    final centroTapa = Offset(ancho / 2, alto * 0.17 - elevacion);
    canvas.translate(centroTapa.dx, centroTapa.dy);
    canvas.rotate(-0.35 * aperturaTapa);
    final tapa = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: ancho * 0.72, height: alto * 0.1),
      Radius.circular(ancho * 0.05),
    );
    canvas.drawRRect(
      tapa,
      Paint()
        ..shader = _degradadoMarino.createShader(tapa.outerRect),
    );
    canvas.drawRRect(
      tapa,
      Paint()
        ..color = ColoresApp.bordeCupula
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.restore();
  }

  void _pintarCandado(Canvas canvas, Rect area) {
    final centro = Offset(area.center.dx, area.bottom - area.height * 0.12);
    final radio = area.width * 0.13;
    canvas.drawCircle(centro, radio, Paint()..color = ColoresApp.primario);
    canvas.drawCircle(
      centro,
      radio,
      Paint()
        ..color = ColoresApp.bordeCupula
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final icono = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.lock_outline.codePoint),
        style: TextStyle(
          fontFamily: Icons.lock_outline.fontFamily,
          package: Icons.lock_outline.fontPackage,
          fontSize: radio * 1.1,
          color: ColoresApp.sobrePrimario,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    icono.paint(canvas, centro - Offset(icono.width / 2, icono.height / 2));
  }

  @override
  bool shouldRepaint(_PintorFrasco anterior) =>
      anterior.brillo != brillo ||
      anterior.aperturaTapa != aperturaTapa ||
      anterior.conRecuerdos != conRecuerdos ||
      anterior.conCandado != conCandado;
}
