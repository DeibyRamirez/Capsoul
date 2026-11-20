import 'package:flutter/material.dart';

import '../../../../nucleo/tema/colores_app.dart';
import '../../../../nucleo/tema/tema_app.dart';
import '../../dominio/reto.dart';

class TarjetaRetoDiario extends StatelessWidget {
  const TarjetaRetoDiario({
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
    final completada = reto.completado;

    return Material(
      color: ColoresApp.tarjeta,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TemaApp.radioGrande),
        side: const BorderSide(color: ColoresApp.bordeTarjeta),
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
                  Icon(Icons.wb_sunny_outlined, color: ColoresApp.acento),
                  const SizedBox(width: 8),
                  Text(
                    'Entrada del día',
                    style: tema.textTheme.titleSmall?.copyWith(
                      color: ColoresApp.textoSecundario,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right, color: ColoresApp.atenuado),
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
                      color: completada
                          ? ColoresApp.primario.withValues(alpha: 0.10)
                          : ColoresApp.fondoInicio,
                      borderRadius: BorderRadius.circular(TemaApp.radioPildora),
                      border: Border.all(
                        color: completada
                            ? Colors.transparent
                            : ColoresApp.bordeTarjeta,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          completada
                              ? Icons.check_circle_outline
                              : Icons.schedule_outlined,
                          size: 13,
                          color: ColoresApp.primario,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          completada ? 'Completada' : 'Pendiente',
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
                        Icon(
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
