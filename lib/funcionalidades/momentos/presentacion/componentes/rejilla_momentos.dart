import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../nucleo/componentes/estado_vacio_capsoul.dart';
import '../../../../nucleo/componentes/ilustracion_capsoul.dart';
import '../../../../nucleo/enrutador/rutas_app.dart';
import '../../dominio/momento.dart';
import 'tarjeta_momento.dart';

/// Rejilla perezosa de 2 columnas con los momentos del usuario.
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
      return SliverEstadoVacioCapsoul(
        mensaje: mensajeVacio,
        ilustracion: NombresIlustracion.vacioMomentos,
        icono: Icons.auto_awesome_mosaic_outlined,
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      sliver: SliverGrid.builder(
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
      ),
    );
  }
}
