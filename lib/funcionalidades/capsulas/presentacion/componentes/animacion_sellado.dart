import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../nucleo/componentes/frasco_luminoso.dart';
import '../../../../nucleo/componentes/ilustracion_capsoul.dart';
import '../../../../nucleo/tema/colores_app.dart';
import '../../../../nucleo/tema/movimiento_app.dart';
import '../../../../nucleo/tema/tipografia_app.dart';

/// Ceremonia corta al sellar. Si el sistema pide menos movimiento, no se muestra.
Future<void> mostrarAnimacionSellado(BuildContext context) {
  if (MediaQuery.disableAnimationsOf(context)) return Future<void>.value();
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Sellando cápsula',
    barrierColor: ColoresApp.medianoche.withValues(alpha: 0.92),
    transitionDuration: MovimientoApp.rapido,
    pageBuilder: (contexto, _, _) => const _Sellado(),
  );
}

class _Sellado extends StatefulWidget {
  const _Sellado();

  @override
  State<_Sellado> createState() => _EstadoSellado();
}

class _EstadoSellado extends State<_Sellado>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controlador = AnimationController(
    vsync: this,
    duration: MovimientoApp.lento,
  );
  late final Animation<double> _escala = CurvedAnimation(
    parent: _controlador,
    curve: const Interval(0, 0.7, curve: Curves.easeOutBack),
  );
  late final Animation<double> _texto = CurvedAnimation(
    parent: _controlador,
    curve: const Interval(0.45, 1, curve: Curves.easeOut),
  );

  @override
  void initState() {
    super.initState();
    HapticFeedback.lightImpact();
    _controlador.forward().whenComplete(() {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: Tween<double>(begin: 0.86, end: 1).animate(_escala),
              child: const IlustracionCapsoul(
                nombre: NombresIlustracion.capsulaSellada,
                ancho: 180,
                alto: 180,
                fallback: FrascoLuminoso(
                  tamano: 180,
                  brillo: 0.9,
                  conCandado: true,
                  conRecuerdos: true,
                ),
              ),
            ),
            const SizedBox(height: 24),
            FadeTransition(
              opacity: _texto,
              child: const Text(
                'Quedó sellada',
                style: TextStyle(
                  fontFamily: TipografiaApp.fuenteTitulos,
                  fontSize: 28,
                  color: ColoresApp.sobrePrimario,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
