import 'package:flutter/material.dart';

import '../../../../nucleo/formato/fechas.dart';
import '../../../../nucleo/tema/colores_app.dart';
import '../../../../nucleo/tema/tema_app.dart';
import '../../../recuerdos/dominio/recuerdo.dart';
import '../../../recuerdos/presentacion/componentes/miniatura_recuerdo_firmada.dart';

/// Fila de un recuerdo elegido para una cápsula o momento, con "Quitar".
class TarjetaRecuerdoElegido extends StatelessWidget {
  const TarjetaRecuerdoElegido({
    super.key,
    required this.recuerdo,
    required this.alQuitar,
  });

  final Recuerdo recuerdo;
  final VoidCallback? alQuitar;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: ColoresApp.sobrePrimario,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(TemaApp.radioPequeno),
              child: SizedBox.square(
                dimension: 56,
                child: MiniaturaRecuerdoFirmada(
                  recuerdo: recuerdo,
                  tamanoIcono: 24,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recuerdo.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: ColoresApp.sobreSuperficie,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${recuerdo.tipo.etiqueta} · '
                    '${formatearFechaCorta(recuerdo.fechaRecuerdo)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: ColoresApp.atenuado),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Quitar',
              icon: const Icon(Icons.close),
              color: ColoresApp.atenuado,
              onPressed: alQuitar,
            ),
          ],
        ),
      ),
    );
  }
}
