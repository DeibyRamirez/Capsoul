import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../nucleo/enrutador/rutas_app.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../dominio/recuerdo.dart';
import 'componentes/visor_publicacion_recuerdo.dart';

/// Abre el visor tipo publicación (no navega al detalle).
Future<void> mostrarVisorPublicacionRecuerdo(
  BuildContext context,
  WidgetRef ref,
  Recuerdo recuerdo,
) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Cerrar publicación',
    barrierColor: ColoresApp.medianoche.withValues(alpha: 0.6),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (contexto, _, _) => VisorPublicacionRecuerdo(
      recuerdo: recuerdo,
      alEditar: () {
        Navigator.of(contexto).pop();
        contexto.push(RutasApp.editarRecuerdoDe(recuerdo.id));
      },
    ),
  );
}
