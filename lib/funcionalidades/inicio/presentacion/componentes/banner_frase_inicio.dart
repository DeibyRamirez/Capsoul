import 'package:flutter/material.dart';

import '../../../../nucleo/componentes/frasco_luminoso.dart';
import '../../../../nucleo/tema/colores_app.dart';
import '../../../../nucleo/tema/degradados_capsoul.dart';
import '../../../../nucleo/tema/tema_app.dart';
import '../heroes_inicio.dart';

/// Banner medianoche con la frase de Capsoul.
class BannerFraseInicio extends StatefulWidget {
  const BannerFraseInicio({super.key});

  @override
  State<BannerFraseInicio> createState() => _EstadoBannerFraseInicio();
}

class _EstadoBannerFraseInicio extends State<BannerFraseInicio>
    with SingleTickerProviderStateMixin {
  AnimationController? _brillo;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _brillo?.dispose();
      _brillo = null;
      return;
    }
    if (_brillo != null) return;
    _brillo = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
      lowerBound: 1,
      upperBound: 1.04,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _brillo?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brillo = _brillo;
    Widget frasco = const FrascoLuminoso(tamano: 64, brillo: 1);
    if (brillo != null) {
      frasco = AnimatedBuilder(
        animation: brillo,
        builder: (context, child) =>
            Transform.scale(scale: brillo.value, child: child),
        child: frasco,
      );
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 10, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(TemaApp.radioGrande),
        gradient: DegradadosCapsoul.banner,
        boxShadow: TemaApp.sombraTarjeta,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'No se trata de tener más tiempo, sino de dejar lo que importa.',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: ColoresApp.sobrePrimario, height: 1.4),
            ),
          ),
          const SizedBox(width: 8),
          Hero(
            tag: HeroesInicio.frase,
            child: Material(type: MaterialType.transparency, child: frasco),
          ),
        ],
      ),
    );
  }
}
