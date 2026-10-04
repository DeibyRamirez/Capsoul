import 'package:flutter/material.dart';

import '../../../../nucleo/tema/colores_app.dart';

/// Logo "cápsoul", slogan y campana de avisos.
class EncabezadoInicio extends StatelessWidget {
  const EncabezadoInicio({super.key, required this.alTocarCampana});

  final VoidCallback alTocarCampana;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    return Row(
      children: [
        const SizedBox(width: 48),
        Expanded(
          child: Column(
            children: [
              Text(
                'cápsoul',
                style: estilos.displaySmall?.copyWith(
                  color: ColoresApp.sobrePrimario,
                  fontFamily: 'serif',
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1,
                ),
              ),
              Text(
                'Pequeñas herencias, grandes recuerdos',
                textAlign: TextAlign.center,
                style: estilos.bodyMedium?.copyWith(
                  color: ColoresApp.sobrePrimario.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Avisos',
          onPressed: alTocarCampana,
          icon: const Icon(Icons.notifications_none_outlined),
          color: ColoresApp.sobrePrimario,
        ),
      ],
    );
  }
}
