import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../nucleo/componentes/tarjeta_capsoul.dart';
import '../../../../nucleo/enrutador/rutas_app.dart';
import '../../../../nucleo/tema/colores_app.dart';
import '../../../../nucleo/tema/tema_app.dart';
import '../heroes_legado.dart';

class TarjetaSeguridadLegado extends StatelessWidget {
  const TarjetaSeguridadLegado({super.key});

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Hero(
        tag: HeroesLegado.seguridad,
        child: Material(
          type: MaterialType.transparency,
          child: TarjetaCapsoul(
            icono: Icons.verified_user_outlined,
            titulo: 'Tu espacio seguro',
            alTocar: () => context.push(RutasApp.legadoSeguridad),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tus recuerdos y cápsulas quedan a salvo. '
                        'Solo se abren cuando se cumplen las condiciones que definas.',
                        style: estilos.bodyMedium?.copyWith(
                          color: ColoresApp.atenuado,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Ver seguridad y respaldo',
                              style: estilos.labelLarge?.copyWith(
                                color: ColoresApp.primario,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.chevron_right,
                            color: ColoresApp.primario,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(TemaApp.radioMediano),
                  child: Image.asset(
                    'assets/Fondo.jpg',
                    width: 88,
                    height: 88,
                    fit: BoxFit.cover,
                    excludeFromSemantics: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
