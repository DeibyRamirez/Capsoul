import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../nucleo/enrutador/rutas_app.dart';
import '../../../../nucleo/tema/colores_app.dart';
import '../../../recuerdos/dominio/recuerdo.dart';
import '../../../recuerdos/presentacion/componentes/miniatura_recuerdo_firmada.dart';

/// Rejilla de 3 columnas con los recuerdos del usuario (estilo Instagram).
class RejillaElementosPerfil extends StatelessWidget {
  const RejillaElementosPerfil({
    super.key,
    required this.recuerdos,
    this.mensajeVacio = 'Aún no tienes recuerdos.',
  });

  final List<Recuerdo> recuerdos;
  final String mensajeVacio;

  @override
  Widget build(BuildContext context) {
    if (recuerdos.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(
              Icons.photo_library_outlined,
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
      padding: const EdgeInsets.only(bottom: 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        childAspectRatio: 1,
      ),
      itemCount: recuerdos.length,
      itemBuilder: (context, indice) {
        final recuerdo = recuerdos[indice];
        return Semantics(
          button: true,
          label: recuerdo.titulo ?? recuerdo.tipo.etiqueta,
          child: Material(
            color: ColoresApp.superficie,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => context.push(RutasApp.detalleRecuerdoDe(recuerdo.id)),
              child: MiniaturaRecuerdoFirmada(recuerdo: recuerdo),
            ),
          ),
        );
      },
    );
  }
}
