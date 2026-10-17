import 'package:flutter/material.dart';

import '../../../../nucleo/tema/colores_app.dart';
import '../../../../nucleo/tema/tema_app.dart';
import '../../dominio/reto.dart';
import '../clasificacion_retos_ui.dart';

class TarjetaRetoEspecial extends StatelessWidget {
  const TarjetaRetoEspecial({
    super.key,
    required this.reto,
    required this.diaActual,
    required this.alTocar,
  });

  final Reto reto;
  final int diaActual;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final meta = ClasificacionRetosUi.metaEspecialDias;
    final progreso = (diaActual / meta).clamp(0.0, 1.0);

    return Material(
      color: ColoresApp.pastelRosa.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TemaApp.radioGrande),
        side: BorderSide(color: ColoresApp.pastelRosa.withValues(alpha: 0.8)),
      ),
      child: InkWell(
        onTap: alTocar,
        borderRadius: BorderRadius.circular(TemaApp.radioGrande),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.card_giftcard_outlined, color: ColoresApp.primario),
                  const SizedBox(width: 8),
                  Text(
                    'Reto especial',
                    style: tema.textTheme.titleSmall?.copyWith(
                      color: ColoresApp.primario,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                reto.titulo,
                style: tema.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: ColoresApp.textoPrincipal,
                ),
              ),
              if (reto.descripcion != null && reto.descripcion!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  reto.descripcion!,
                  style: tema.textTheme.bodyMedium?.copyWith(
                    color: ColoresApp.textoSecundario,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(TemaApp.radioPequeno),
                child: LinearProgressIndicator(
                  value: progreso,
                  minHeight: 8,
                  backgroundColor: ColoresApp.tarjeta,
                  color: ColoresApp.primario,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Día $diaActual de $meta',
                style: tema.textTheme.bodySmall?.copyWith(
                  color: ColoresApp.textoSecundario,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
