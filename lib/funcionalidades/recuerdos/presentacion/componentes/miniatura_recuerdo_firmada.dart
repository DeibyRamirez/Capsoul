import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../aplicacion/proveedores_recuerdos.dart';
import '../../dominio/enlace_medio.dart';
import '../../dominio/recuerdo.dart';
import 'miniatura_recuerdo.dart';

/// [MiniaturaRecuerdo] que, para fotos y videos, muestra la miniatura de
/// 480 px (nunca el original): de la caché del dispositivo por `public_id` o,
/// si falta, descargada con un enlace de `firmar-medio`. Mientras carga o si
/// falla se ve el respaldo de marca.
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
    final solicitud = solicitudMedioDe(recuerdo, VarianteMedio.miniatura);
    final miniatura = solicitud == null
        ? null
        : ref.watch(proveedorArchivoMedio(solicitud)).value;
    return MiniaturaRecuerdo(
      recuerdo: recuerdo,
      tamanoIcono: tamanoIcono,
      imagen: miniatura == null
          ? null
          : Image.file(
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
