import 'package:flutter/material.dart';

import '../../../../nucleo/tema/colores_app.dart';
import '../../../../nucleo/tema/tema_app.dart';
import '../../dominio/reto.dart';
import '../clasificacion_retos_ui.dart';

class TarjetaRetoSemanal extends StatelessWidget {
  const TarjetaRetoSemanal({
    super.key,
    required this.reto,
    required this.indice,
    required this.alTocar,
  });

  final Reto reto;
  final int indice;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final icono = indice.isEven ? Icons.eco_outlined : Icons.favorite_outline;
    final numerador = numeradorProgresoSemanal(indice, reto);

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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icono, color: ColoresApp.acento),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reto.titulo,
                      style: tema.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: ColoresApp.textoPrincipal,
                      ),
                    ),
                    if (reto.descripcion != null && reto.descripcion!.isNotEmpty)
                      Text(
                        reto.descripcion!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tema.textTheme.bodySmall?.copyWith(
                          color: ColoresApp.textoSecundario,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                '$numerador/7',
                style: tema.textTheme.labelLarge?.copyWith(
                  color: ColoresApp.acento,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: ColoresApp.atenuado),
            ],
          ),
        ),
      ),
    );
  }
}
