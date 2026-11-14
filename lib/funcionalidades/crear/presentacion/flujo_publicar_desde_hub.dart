import 'package:flutter/material.dart';

import '../../elementos/dominio/elemento_borrador.dart';
import '../../recuerdos/dominio/recuerdo.dart';
import 'pantalla_publicar_rapido.dart';

/// Tras capturar en el hub, abre publicación rápida.
Future<Recuerdo?> continuarPublicacionDesdeHub(
  BuildContext context,
  ElementoBorrador borrador,
) {
  if (!context.mounted) return Future.value();
  return mostrarPublicarRapido(context, borrador);
}
