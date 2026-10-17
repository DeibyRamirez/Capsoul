import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../nucleo/enrutador/rutas_app.dart';
import '../../../../nucleo/tema/colores_app.dart';

class TarjetaSeguridadLegado extends StatelessWidget {
  const TarjetaSeguridadLegado({super.key});

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Material(
        color: ColoresApp.primario,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => context.push(RutasApp.legadoSeguridad),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.verified_user_outlined, color: ColoresApp.sobrePrimario, size: 32),
                const SizedBox(height: 12),
                Text(
                  'Todo está protegido',
                  style: estilos.titleMedium?.copyWith(
                    color: ColoresApp.sobrePrimario,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tu información y tus legados están guardados de forma segura. '
                  'Solo se liberan según las condiciones que definas.',
                  style: estilos.bodyMedium?.copyWith(
                    color: ColoresApp.sobrePrimario.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'Ver seguridad y respaldo',
                      style: estilos.labelLarge?.copyWith(
                        color: ColoresApp.sobrePrimario,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, color: ColoresApp.sobrePrimario),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
