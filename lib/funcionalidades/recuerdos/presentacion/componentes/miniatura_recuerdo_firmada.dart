import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../aplicacion/proveedores_recuerdos.dart';
import '../../dominio/recuerdo.dart';
import 'miniatura_recuerdo.dart';

/// [MiniaturaRecuerdo] que, para fotos y videos, carga la miniatura firmada
/// del servidor (Edge Function `firmar-medio`). Mientras carga o si falla se
/// ve el respaldo de marca.
class MiniaturaRecuerdoFirmada extends ConsumerWidget {
  const MiniaturaRecuerdoFirmada({
    super.key,
    required this.recuerdo,
    this.tamanoIcono = 30,
  });

  final Recuerdo recuerdo;
  final double tamanoIcono;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final miniatura = recuerdo.esVisual && recuerdo.publicId != null
        ? ref.watch(proveedorUrlMedio(recuerdo.id)).value?.urlMiniatura
        : null;
    return MiniaturaRecuerdo(
      recuerdo: recuerdo,
      tamanoIcono: tamanoIcono,
      imagen: miniatura == null
          ? null
          : Image.network(
              miniatura,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              frameBuilder: (context, hijo, cuadro, sincronica) =>
                  sincronica || cuadro != null
                      ? hijo
                      : const SizedBox.shrink(),
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
    );
  }
}
