import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../nucleo/componentes/avisos_emergentes.dart';
import '../../../nucleo/errores/fallo_app.dart';
import '../aplicacion/proveedores_elementos.dart';
import '../dominio/elemento_borrador.dart';
import '../dominio/tipo_elemento.dart';

/// Abre el selector del sistema y devuelve el borrador por [Navigator.pop].
Future<void> importarMedioYPop(
  BuildContext context,
  WidgetRef ref,
  TipoElemento tipo,
) async {
  try {
    final borrador = await ref.read(proveedorImportadorMedios).importar(tipo);
    if (borrador != null && context.mounted) context.pop(borrador);
  } on FalloApp catch (fallo) {
    if (context.mounted) mostrarAvisoError(context, fallo);
  }
}

/// Importa sin cerrar la ruta actual (p. ej. antes de guardar recuerdo).
Future<ElementoBorrador?> importarMedio(
  WidgetRef ref,
  TipoElemento tipo,
) async {
  return ref.read(proveedorImportadorMedios).importar(tipo);
}
