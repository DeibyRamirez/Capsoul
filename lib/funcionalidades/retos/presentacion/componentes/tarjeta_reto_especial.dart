import 'package:flutter/material.dart';

import '../../../../nucleo/tema/colores_app.dart';
import '../../../../nucleo/tema/tema_app.dart';
import '../../dominio/reto.dart';

class TarjetaRetoEspecial extends StatelessWidget {
  const TarjetaRetoEspecial({
    super.key,
    required this.reto,
    required this.alTocar,
  });

  final Reto reto;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final pasos = reto.pasos.length;

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
                  Icon(
                    Icons.card_giftcard_outlined,
                    color: ColoresApp.primario,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Entrada especial',
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
              Wrap(
                spacing: 10,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: ColoresApp.primario.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(TemaApp.radioPildora),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.flag_outlined,
                          size: 13,
                          color: ColoresApp.primario,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Meta final del Diario',
                          style: tema.textTheme.labelSmall?.copyWith(
                            color: ColoresApp.primario,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (pasos > 0)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.checklist_rounded,
                          size: 14,
                          color: ColoresApp.atenuado,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$pasos ${pasos == 1 ? 'paso' : 'pasos'}',
                          style: tema.textTheme.labelSmall?.copyWith(
                            color: ColoresApp.atenuado,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
