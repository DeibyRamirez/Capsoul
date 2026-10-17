import 'package:flutter/material.dart';

import '../../../../nucleo/tema/colores_app.dart';
import '../../../../nucleo/tema/tema_app.dart';
import '../../dominio/reto.dart';
import '../clasificacion_retos_ui.dart';

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
    final total = puntosDiariosTotal(reto);
    final rellenos = puntosDiariosRellenos(reto);

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
                    'Reto diario',
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
              Row(
                children: List.generate(total, (i) {
                  final activo = i < rellenos;
                  return Padding(
                    padding: EdgeInsets.only(right: i < total - 1 ? 8 : 0),
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: activo ? ColoresApp.primario : ColoresApp.bordeTarjeta,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
