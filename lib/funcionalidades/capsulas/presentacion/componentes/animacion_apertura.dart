import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../nucleo/componentes/frasco_luminoso.dart';
import '../../../../nucleo/tema/colores_app.dart';
import '../../../../nucleo/tema/movimiento_app.dart';
import '../../../../nucleo/tema/tema_app.dart';

/// Muestra la animación de apertura a pantalla completa y espera a que
/// termine (o a que el usuario toque para saltarla).
Future<void> mostrarAnimacionApertura(BuildContext context) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Abriendo cápsula',
    barrierColor: ColoresApp.medianoche.withValues(alpha: 0.94),
    transitionDuration: MovimientoApp.rapido,
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
  late final List<_Chispa> _chispas = _generarChispas();

  @override
  void initState() {
    super.initState();
    _controlador.forward().whenComplete(_terminar);
  }

  bool _haptico = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // El cielo en bucle sí se apaga con movimiento reducido. Esta ceremonia
    // es de una sola vez y tiene que terminar sola: si se cancela al instante,
    // quien abre la cápsula no llega a ver el frasco.
    if (MediaQuery.disableAnimationsOf(context) || _haptico) return;
    _haptico = true;
    HapticFeedback.lightImpact();
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
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _PintorLucesSubiendo(
                    progreso: _luces,
                    chispas: _chispas,
                  ),
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: Listenable.merge([_brillo, _tapa]),
                  builder: (context, _) {
                    final pulso = 1 + 0.06 * math.sin(_brillo.value * math.pi);
                    return Transform.scale(
                      scale: pulso,
                      child: FrascoLuminoso(
                        tamano: 260,
                        brillo: 0.25 + 0.75 * _brillo.value,
                        aperturaTapa: _tapa.value,
                        conRecuerdos: true,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                FadeTransition(
                  opacity: _texto,
                  child: Text(
                    '¡Tu cápsula se abrió!',
                    style: estilos.headlineSmall?.copyWith(
                      color: ColoresApp.sobrePrimario,
                      fontFamily: TemaApp.fuenteTitulos,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _terminar,
                  child: const Text(
                    'Saltar',
                    style: TextStyle(color: ColoresApp.sobrePrimario),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static List<_Chispa> _generarChispas() {
    final aleatorio = math.Random(5);
    return [
      for (var i = 0; i < 28; i++)
        _Chispa(
          angulo: -math.pi / 2 + (aleatorio.nextDouble() - 0.5) * 1.6,
          distancia: 0.4 + 0.6 * aleatorio.nextDouble(),
          factor: 0.7 + 0.3 * aleatorio.nextDouble(),
          radio: 2 + aleatorio.nextDouble() * 3,
        ),
    ];
  }
}

class _Chispa {
  const _Chispa({
    required this.angulo,
    required this.distancia,
    required this.factor,
    required this.radio,
  });

  final double angulo;
  final double distancia;
  final double factor;
  final double radio;
}

/// Luces que salen del frasco y suben desvaneciéndose.
class _PintorLucesSubiendo extends CustomPainter {
  _PintorLucesSubiendo({required this.progreso, required this.chispas})
    : super(repaint: progreso);

  final Animation<double> progreso;
  final List<_Chispa> chispas;

  static final Paint _halo = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

  @override
  void paint(Canvas canvas, Size size) {
    final avanceGlobal = progreso.value;
    if (avanceGlobal <= 0) return;
    final origen = Offset(size.width / 2, size.height / 2 - 90);
    for (final chispa in chispas) {
      final avance = (avanceGlobal * chispa.factor).clamp(0.0, 1.0);
      final centro =
          origen +
          Offset(math.cos(chispa.angulo), math.sin(chispa.angulo)) *
              size.height *
              0.45 *
              chispa.distancia *
              avance;
      _halo.color = ColoresApp.sobrePrimario.withValues(
        alpha: ((1 - avance) * 0.9).clamp(0, 1),
      );
      canvas.drawCircle(centro, chispa.radio * 3, _halo);
    }
  }

  @override
  bool shouldRepaint(_PintorLucesSubiendo anterior) =>
      !identical(anterior.progreso, progreso) ||
      !identical(anterior.chispas, chispas);
}
