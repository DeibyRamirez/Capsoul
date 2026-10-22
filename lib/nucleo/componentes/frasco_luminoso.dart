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

  static final Paint _vidrio = Paint();
  static final Paint _halo = Paint();
  static final Paint _borde = Paint()
    ..color = ColoresApp.bordeCupula
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  static final Paint _reflejo = Paint()
    ..color = ColoresApp.sobrePrimario.withValues(alpha: 0.35)
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  static final Paint _luz = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  static final Paint _foto = Paint()
    ..color = ColoresApp.sobrePrimario.withValues(alpha: 0.92);
  static final Paint _fotoInterior = Paint();
  static final Paint _tapaRelleno = Paint();
  static final Paint _tapaBorde = Paint()
    ..color = ColoresApp.bordeCupula
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  static final Paint _candadoFondo = Paint()..color = ColoresApp.primario;
  static final Paint _candadoBorde = Paint()
    ..color = ColoresApp.bordeCupula
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

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

    _halo.shader = RadialGradient(
      colors: [
        ColoresApp.sobrePrimario.withValues(alpha: 0.55 * brillo),
        ColoresApp.acento.withValues(alpha: 0.18 * brillo),
        ColoresApp.acento.withValues(alpha: 0),
      ],
      stops: const [0, 0.55, 1],
    ).createShader(
      Rect.fromCircle(center: cuerpo.center, radius: alto * 0.62),
    );
    canvas.drawCircle(cuerpo.center, alto * 0.62, _halo);

    _vidrio.shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        ColoresApp.sobrePrimario.withValues(alpha: 0.45),
        ColoresApp.acento.withValues(alpha: 0.35),
        ColoresApp.primario.withValues(alpha: 0.55),
      ],
    ).createShader(cuerpo.outerRect);
    canvas.drawRRect(cuerpo, _vidrio);

    if (conRecuerdos) _pintarRecuerdos(canvas, cuerpo.outerRect);
    _pintarLuces(canvas, cuerpo.outerRect);

    _reflejo.strokeWidth = ancho * 0.035;
    canvas.drawArc(
      cuerpo.outerRect.deflate(ancho * 0.08),
      math.pi * 1.05,
      math.pi * 0.35,
      false,
      _reflejo,
    );
    canvas.drawRRect(cuerpo, _borde);

    _pintarTapa(canvas, size);
    if (conCandado) _pintarCandado(canvas, cuerpo.outerRect);
  }

  static final List<({double x, double y, double r})> _luces = _generarLuces();

  static List<({double x, double y, double r})> _generarLuces() {
    final aleatorio = math.Random(7);
    return [
      for (var i = 0; i < 16; i++)
        (
          x: 0.15 + 0.7 * aleatorio.nextDouble(),
          y: 0.12 + 0.78 * aleatorio.nextDouble(),
          r: 0.015 + 0.02 * aleatorio.nextDouble(),
        ),
    ];
  }

  void _pintarLuces(Canvas canvas, Rect area) {
    if (brillo <= 0) return;
    _luz.color = ColoresApp.sobrePrimario.withValues(alpha: brillo.clamp(0, 1));
    for (final luz in _luces) {
      final radio = area.width * luz.r;
      canvas.drawCircle(
        Offset(area.left + area.width * luz.x, area.top + area.height * luz.y),
        radio * 3,
        _luz,
      );
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
      canvas.drawRRect(marco, _foto);
      final interior = marco.deflate(area.width * 0.025);
      _fotoInterior.shader = _degradadoMarino.createShader(interior.outerRect);
      canvas.drawRRect(interior, _fotoInterior);
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
    _tapaRelleno.shader = _degradadoMarino.createShader(tapa.outerRect);
    canvas.drawRRect(tapa, _tapaRelleno);
    canvas.drawRRect(tapa, _tapaBorde);
    canvas.restore();
  }

  static TextPainter? _iconoCandado;
  static double _tamanoIconoCandado = -1;

  void _pintarCandado(Canvas canvas, Rect area) {
    final centro = Offset(area.center.dx, area.bottom - area.height * 0.12);
    final radio = area.width * 0.13;
    canvas.drawCircle(centro, radio, _candadoFondo);
    canvas.drawCircle(centro, radio, _candadoBorde);
    final tamano = radio * 1.1;
    var pintado = _iconoCandado;
    if (pintado == null || _tamanoIconoCandado != tamano) {
      _tamanoIconoCandado = tamano;
      pintado = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(Icons.lock_outline.codePoint),
          style: TextStyle(
            fontFamily: Icons.lock_outline.fontFamily,
            package: Icons.lock_outline.fontPackage,
            fontSize: tamano,
            color: ColoresApp.sobrePrimario,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      _iconoCandado = pintado;
    }
    pintado.paint(canvas, centro - Offset(pintado.width / 2, pintado.height / 2));
  }

  @override
  bool shouldRepaint(_PintorFrasco anterior) =>
      anterior.brillo != brillo ||
      anterior.aperturaTapa != aperturaTapa ||
      anterior.conRecuerdos != conRecuerdos ||
      anterior.conCandado != conCandado;
}
