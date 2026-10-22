import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../tema/colores_app.dart';
import '../tema/degradados_capsoul.dart';

enum _TipoParticula { estrella, luciernaga }

class _Particula {
  const _Particula({
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

/// Fondo nocturno con estrellas y luciérnagas.
///
/// El pintor se repinta solo (el [AnimationController] es su [Listenable]):
/// no hay [setState] por fotograma y el [child] queda fuera de esa capa.
/// La animación se detiene con movimiento reducido, [TickerMode] apagado
/// (otra pestaña u otra ruta) o cuando el cielo sale del viewport.
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
  static final List<_Particula> _particulas = _generarParticulas();

  late final AnimationController _controlador = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  );

  ScrollPosition? _posicion;
  bool _enPantalla = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nueva = Scrollable.maybeOf(context)?.position;
    if (!identical(nueva, _posicion)) {
      _posicion?.removeListener(_alDesplazar);
      _posicion = nueva;
      _posicion?.addListener(_alDesplazar);
    }
    _sincronizarAnimacion();
    WidgetsBinding.instance.addPostFrameCallback((_) => _revisarVisibilidad());
  }

  @override
  void didUpdateWidget(CieloNocturno anterior) {
    super.didUpdateWidget(anterior);
    if (anterior.animado != widget.animado) _sincronizarAnimacion();
  }

  void _alDesplazar() => _revisarVisibilidad();

  void _revisarVisibilidad() {
    if (!mounted) return;
    final objeto = context.findRenderObject();
    if (objeto is! RenderBox || !objeto.attached || !objeto.hasSize) return;
    final viewport = RenderAbstractViewport.maybeOf(objeto);
    bool visible;
    if (viewport == null) {
      final origen = objeto.localToGlobal(Offset.zero);
      final tamano = objeto.size;
      final vista = MediaQuery.sizeOf(context);
      visible = origen.dy < vista.height &&
          origen.dy + tamano.height > 0 &&
          origen.dx < vista.width &&
          origen.dx + tamano.width > 0;
    } else {
      try {
        final revelado = viewport.getOffsetToReveal(objeto, 0);
        final inicio = revelado.offset;
        final fin = inicio + objeto.size.height;
        final pixels = _posicion?.pixels ?? inicio;
        final altoVista = _posicion?.viewportDimension ?? objeto.size.height;
        visible = fin > pixels && inicio < pixels + altoVista;
      } catch (_) {
        visible = true;
      }
    }
    if (visible == _enPantalla) return;
    _enPantalla = visible;
    _sincronizarAnimacion();
  }

  void _sincronizarAnimacion() {
    final deshabilitado = MediaQuery.disableAnimationsOf(context);
    final ticker = TickerMode.valuesOf(context).enabled;
    final debe = widget.animado && !deshabilitado && ticker && _enPantalla;
    if (debe) {
      if (!_controlador.isAnimating) _controlador.repeat();
    } else if (_controlador.isAnimating) {
      _controlador.stop();
    }
  }

  @override
  void dispose() {
    _posicion?.removeListener(_alDesplazar);
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cielo = RepaintBoundary(
      child: CustomPaint(
        painter: _PintorCielo(
          particulas: _particulas,
          controlador: _controlador,
          brillo: widget.brillo,
        ),
      ),
    );
    final hijo = widget.child;
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: DegradadosCapsoul.nocturno),
      child: Stack(
        fit: hijo == null ? StackFit.expand : StackFit.passthrough,
        children: [
          if (hijo == null)
            Positioned.fill(child: cielo)
          else ...[
            Positioned.fill(child: cielo),
            RepaintBoundary(child: hijo),
          ],
        ],
      ),
    );
  }

  static List<_Particula> _generarParticulas() {
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
    required this.controlador,
    required this.brillo,
  }) : super(repaint: controlador);

  final List<_Particula> particulas;
  final AnimationController controlador;
  final double brillo;

  static final Paint _estrella = Paint();
  static final Paint _cuerpo = Paint();
  static final Paint _halo = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

  @override
  void paint(Canvas canvas, Size size) {
    final animado = controlador.isAnimating;
    final tiempo = controlador.value;
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
        _estrella.color = ColoresApp.sobrePrimario.withValues(
          alpha: (p.alphaBase * pulso * brillo).clamp(0, 1),
        );
        canvas.drawCircle(centro, p.radio, _estrella);
      } else {
        final ancho = p.radio;
        final alphaCuerpo =
            ((0.35 + 0.4 * pulso) * brillo).clamp(0, 1).toDouble();
        _halo.color = ColoresApp.sobrePrimario.withValues(
          alpha: (alphaCuerpo * 0.45).clamp(0, 1),
        );
        canvas.drawCircle(centro, ancho * 2.2, _halo);
        _cuerpo.color = ColoresApp.sobrePrimario.withValues(alpha: alphaCuerpo);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: centro,
              width: ancho,
              height: ancho * 1.3,
            ),
            Radius.circular(ancho * 0.3),
          ),
          _cuerpo,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_PintorCielo anterior) =>
      anterior.brillo != brillo ||
      !identical(anterior.particulas, particulas) ||
      !identical(anterior.controlador, controlador);
}
