import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../nucleo/componentes/frasco_luminoso.dart';
import '../../../../nucleo/tema/colores_app.dart';

/// Muestra la animación de apertura a pantalla completa y espera a que
/// termine (o a que el usuario toque para saltarla).
Future<void> mostrarAnimacionApertura(BuildContext context) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Abriendo cápsula',
    barrierColor: ColoresApp.primario.withValues(alpha: 0.92),
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (contexto, _, _) => AnimacionAperturaCapsula(
      alTerminar: () => Navigator.of(contexto).pop(),
    ),
  );
}

/// El frasco se ilumina, la tapa se levanta y salen luces hacia arriba.
class AnimacionAperturaCapsula extends StatefulWidget {
  const AnimacionAperturaCapsula({super.key, required this.alTerminar});

  final VoidCallback alTerminar;

  static const Duration duracion = Duration(milliseconds: 2800);

  @override
  State<AnimacionAperturaCapsula> createState() =>
      _EstadoAnimacionAperturaCapsula();
}

class _EstadoAnimacionAperturaCapsula extends State<AnimacionAperturaCapsula>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controlador = AnimationController(
    vsync: this,
    duration: AnimacionAperturaCapsula.duracion,
  );

  late final Animation<double> _brillo = CurvedAnimation(
    parent: _controlador,
    curve: const Interval(0, 0.45, curve: Curves.easeInOut),
  );
  late final Animation<double> _tapa = CurvedAnimation(
    parent: _controlador,
    curve: const Interval(0.4, 0.75, curve: Curves.easeOutBack),
  );
  late final Animation<double> _luces = CurvedAnimation(
    parent: _controlador,
    curve: const Interval(0.5, 1, curve: Curves.easeOut),
  );
  late final Animation<double> _texto = CurvedAnimation(
    parent: _controlador,
    curve: const Interval(0.7, 0.95, curve: Curves.easeIn),
  );

  bool _terminada = false;

  @override
  void initState() {
    super.initState();
    _controlador.forward().whenComplete(_terminar);
  }

  void _terminar() {
    if (_terminada || !mounted) return;
    _terminada = true;
    widget.alTerminar();
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _terminar,
      child: Material(
        type: MaterialType.transparency,
        child: AnimatedBuilder(
          animation: _controlador,
          builder: (context, _) {
            final pulso = 1 + 0.06 * math.sin(_brillo.value * math.pi);
            return Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _PintorLucesSubiendo(progreso: _luces.value),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.scale(
                      scale: pulso,
                      child: FrascoLuminoso(
                        tamano: 260,
                        brillo: 0.25 + 0.75 * _brillo.value,
                        aperturaTapa: _tapa.value,
                        conRecuerdos: true,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Opacity(
                      opacity: _texto.value,
                      child: Text(
                        '¡Tu cápsula se abrió!',
                        style: estilos.headlineSmall?.copyWith(
                          color: ColoresApp.sobrePrimario,
                          fontFamily: 'serif',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Luces que salen del frasco y suben desvaneciéndose.
class _PintorLucesSubiendo extends CustomPainter {
  _PintorLucesSubiendo({required this.progreso});

  final double progreso;

  @override
  void paint(Canvas canvas, Size size) {
    if (progreso <= 0) return;
    final aleatorio = math.Random(5);
    final origen = Offset(size.width / 2, size.height / 2 - 90);
    for (var i = 0; i < 28; i++) {
      final angulo = -math.pi / 2 + (aleatorio.nextDouble() - 0.5) * 1.6;
      final distancia = size.height * 0.45 * (0.4 + 0.6 * aleatorio.nextDouble());
      final avance = (progreso * (0.7 + 0.3 * aleatorio.nextDouble())).clamp(0.0, 1.0);
      final centro = origen +
          Offset(math.cos(angulo), math.sin(angulo)) * distancia * avance;
      final radio = 2 + aleatorio.nextDouble() * 3;
      final opacidad = (1 - avance) * 0.9;
      final halo = Paint()
        ..shader = RadialGradient(
          colors: [
            ColoresApp.sobrePrimario.withValues(alpha: opacidad),
            ColoresApp.sobrePrimario.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: centro, radius: radio * 3));
      canvas.drawCircle(centro, radio * 3, halo);
    }
  }

  @override
  bool shouldRepaint(_PintorLucesSubiendo anterior) =>
      anterior.progreso != progreso;
}
