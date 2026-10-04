import 'package:flutter/material.dart';

import '../../../../nucleo/tema/colores_app.dart';
import '../../../elementos/dominio/validador_medios.dart';
import '../../dominio/uso_medios.dart';

/// "12,3 MB de 200 MB usados" con barra de progreso.
class BarraUsoMedios extends StatelessWidget {
  const BarraUsoMedios({super.key, required this.uso});

  final UsoMedios uso;

  @override
  Widget build(BuildContext context) {
    final casiLleno = uso.fraccion >= 0.9;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${formatearBytes(uso.bytesUsados)} de '
          '${formatearBytes(uso.bytesLimite)} usados',
          style: const TextStyle(fontSize: 12, color: ColoresApp.atenuado),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: uso.fraccion,
            minHeight: 6,
            backgroundColor: ColoresApp.acento.withValues(alpha: 0.15),
            color: casiLleno ? Theme.of(context).colorScheme.error : ColoresApp.acento,
          ),
        ),
      ],
    );
  }
}
