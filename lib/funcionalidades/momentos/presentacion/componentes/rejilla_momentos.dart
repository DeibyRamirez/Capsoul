import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../nucleo/enrutador/rutas_app.dart';
import '../../../../nucleo/tema/colores_app.dart';
import '../../dominio/momento.dart';
import 'tarjeta_momento.dart';

/// Rejilla de 2 columnas con los momentos del usuario.
class RejillaMomentos extends StatelessWidget {
  const RejillaMomentos({
    super.key,
    required this.momentos,
    this.mensajeVacio = 'Aún no tienes momentos publicados.',
  });

  final List<Momento> momentos;
  final String mensajeVacio;

  @override
  Widget build(BuildContext context) {
    if (momentos.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(
              Icons.auto_awesome_mosaic_outlined,
              size: 48,
              color: ColoresApp.acento,
            ),
            const SizedBox(height: 12),
            Text(
              mensajeVacio,
              textAlign: TextAlign.center,
              style: const TextStyle(color: ColoresApp.atenuado),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: momentos.length,
      itemBuilder: (context, indice) {
        final momento = momentos[indice];
        return TarjetaMomento(
          key: ValueKey(momento.id),
          momento: momento,
          alTocar: () => context.push(RutasApp.detalleMomentoDe(momento.id)),
        );
      },
    );
  }
}
