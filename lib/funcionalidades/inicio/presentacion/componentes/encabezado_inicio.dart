import 'package:flutter/material.dart';

import '../../../../nucleo/tema/colores_app.dart';
import '../../../../nucleo/tema/tipografia_app.dart';

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
                'Hola',
                style: TipografiaApp.display.copyWith(color: ColoresApp.primario),
              ),
              Text(
                'cápsoul',
                style: estilos.titleMedium?.copyWith(
                  color: ColoresApp.acento,
                  fontFamily: TipografiaApp.fuenteTitulos,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                'Pequeñas herencias, grandes recuerdos',
                textAlign: TextAlign.center,
                style: estilos.bodySmall?.copyWith(
                  color: ColoresApp.textoSecundario,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Avisos',
          onPressed: alTocarCampana,
          icon: const Icon(Icons.notifications_none_outlined),
          color: ColoresApp.primario,
        ),
      ],
    );
  }
}
