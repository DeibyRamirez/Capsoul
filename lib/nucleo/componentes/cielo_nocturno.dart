import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tema/colores_app.dart';
import '../tema/degradados_capsoul.dart';

enum _TipoParticula { estrella, luciernaga }

class _Particula {
  _Particula({
    required this.tipo,
    required this.baseX,
    required this.baseY,
    required this.radio,
    required this.fase,
    required this.velocidad,
    required this.alphaBase,
  });

  final _TipoParticula tipo;
  final double baseX;
  final double baseY;
  final double radio;
  final double fase;
  final double velocidad;
  final double alphaBase;
}

/// Fondo nocturno con estrellas y luciérnagas animadas.
class CieloNocturno extends StatefulWidget {
  const CieloNocturno({
    super.key,
    this.brillo = 1,
    this.animado = true,
    this.child,
  });

  final double brillo;
  final bool animado;
  final Widget? child;

  @override
  State<CieloNocturno> createState() => _CieloNocturnoState();
}

class _CieloNocturnoState extends State<CieloNocturno>
    with SingleTickerProviderStateMixin {
  late final List<_Particula> _particulas;
  AnimationController? _controlador;

  @override
  void initState() {
    super.initState();
    _particulas = _generarParticulas();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sincronizarAnimacion();
  }

  @override
  void didUpdateWidget(CieloNocturno anterior) {
    super.didUpdateWidget(anterior);
    if (anterior.animado != widget.animado) {
      _sincronizarAnimacion();
    }
  }

  void _sincronizarAnimacion() {
    final deshabilitado = MediaQuery.disableAnimationsOf(context);
    final debeAnimar = widget.animado && !deshabilitado;

    if (debeAnimar && _controlador == null) {
      _controlador = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 8),
      )..repeat();
      _controlador!.addListener(() => setState(() {}));
    } else if (!debeAnimar && _controlador != null) {
      _controlador!.dispose();
      _controlador = null;
    }
  }

  @override
  void dispose() {
    _controlador?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _controlador?.value ?? 0;
    return RepaintBoundary(
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: DegradadosCapsoul.nocturno),
        child: CustomPaint(
          painter: _PintorCielo(
            particulas: _particulas,
            brillo: widget.brillo,
            tiempo: t,
            animado: _controlador != null,
          ),
          child: widget.child,
        ),
      ),
    );
  }

  List<_Particula> _generarParticulas() {
    final aleatorio = math.Random(11);
    final lista = <_Particula>[];
    for (var i = 0; i < 40; i++) {
      lista.add(
        _Particula(
          tipo: _TipoParticula.estrella,
          baseX: aleatorio.nextDouble(),
          baseY: aleatorio.nextDouble() * 0.7,
          radio: 0.6 + aleatorio.nextDouble() * 1.2,
          fase: aleatorio.nextDouble() * math.pi * 2,
          velocidad: 0.8 + aleatorio.nextDouble() * 0.6,
          alphaBase: 0.2 + 0.5 * aleatorio.nextDouble(),
        ),
      );
    }
    for (var i = 0; i < 9; i++) {
      lista.add(
        _Particula(
          tipo: _TipoParticula.luciernaga,
          baseX: aleatorio.nextDouble(),
          baseY: 0.05 + 0.6 * aleatorio.nextDouble(),
          radio: 5 + aleatorio.nextDouble() * 6,
          fase: aleatorio.nextDouble() * math.pi * 2,
          velocidad: 0.5 + aleatorio.nextDouble() * 0.8,
          alphaBase: 0.55,
        ),
      );
    }
    return lista;
  }
}

class _PintorCielo extends CustomPainter {
  _PintorCielo({
    required this.particulas,
    required this.brillo,
    required this.tiempo,
    required this.animado,
  });

  final List<_Particula> particulas;
  final double brillo;
  final double tiempo;
  final bool animado;

  @override
  void paint(Canvas canvas, Size size) {
    final estrella = Paint();
    for (final p in particulas) {
      final pulso = animado
          ? 0.5 + 0.5 * math.sin(p.fase + tiempo * math.pi * 2 * p.velocidad)
          : 1.0;
      final derivaX = animado
          ? math.sin(p.fase + tiempo * math.pi * 2 * p.velocidad) * 4
          : 0.0;
      final derivaY = animado
          ? math.cos(p.fase * 1.3 + tiempo * math.pi * 2 * p.velocidad) * 3
          : 0.0;
      final centro = Offset(
        p.baseX * size.width + derivaX,
        p.baseY * size.height + derivaY,
      );

      if (p.tipo == _TipoParticula.estrella) {
        estrella.color = ColoresApp.sobrePrimario
            .withValues(alpha: p.alphaBase * pulso * brillo);
        canvas.drawCircle(centro, p.radio, estrella);
      } else {
        final ancho = p.radio;
        final alphaCuerpo = (0.35 + 0.4 * pulso) * brillo;
        final halo = Paint()
          ..shader = RadialGradient(
            colors: [
              ColoresApp.sobrePrimario.withValues(alpha: alphaCuerpo * 0.5),
              ColoresApp.sobrePrimario.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: centro, radius: ancho * 2.4));
        canvas.drawCircle(centro, ancho * 2.4, halo);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: centro,
              width: ancho,
              height: ancho * 1.3,
            ),
            Radius.circular(ancho * 0.3),
          ),
          Paint()
            ..color =
                ColoresApp.sobrePrimario.withValues(alpha: alphaCuerpo),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_PintorCielo anterior) =>
      anterior.brillo != brillo ||
      anterior.tiempo != tiempo ||
      anterior.animado != animado;
}
