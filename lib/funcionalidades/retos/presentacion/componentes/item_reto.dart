import 'package:flutter/material.dart';

import '../../../../nucleo/tema/colores_app.dart';
import '../../../../nucleo/tema/tema_app.dart';
import '../../dominio/reto.dart';

class ItemReto extends StatelessWidget {
  const ItemReto({super.key, required this.reto});

  final Reto reto;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      color: ColoresApp.sobrePrimario,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TemaApp.radioGrande),
        side: BorderSide(color: ColoresApp.atenuado.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              reto.completado ? Icons.check_circle : Icons.radio_button_unchecked,
              color: reto.completado ? ColoresApp.acento : ColoresApp.atenuado,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reto.titulo,
                    style: tema.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: ColoresApp.sobreSuperficie,
                    ),
                  ),
                  if (reto.descripcion != null && reto.descripcion!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      reto.descripcion!,
                      style: tema.textTheme.bodyMedium?.copyWith(
                        color: ColoresApp.atenuado,
                      ),
                    ),
                  ],
                  if (reto.pasos.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ...reto.pasos.map(
                      (paso) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          '• $paso',
                          style: tema.textTheme.bodySmall?.copyWith(
                            color: ColoresApp.atenuado,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
