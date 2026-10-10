import 'package:flutter/material.dart';

import '../../../recuerdos/dominio/recuerdo.dart';
import '../../dominio/referencia_musica.dart';
import 'escena_preview_musica.dart';

/// Detalle de un recuerdo tipo música o bloque musical en una foto.
class VistaRecuerdoMusica extends StatelessWidget {
  const VistaRecuerdoMusica({
    super.key,
    required this.referencia,
    this.recuerdo,
  });

  final ReferenciaMusica referencia;
  final Recuerdo? recuerdo;

  @override
  Widget build(BuildContext context) {
    return EscenaPreviewMusica(
      referencia: referencia,
      reproducirAutomaticamente: false,
      alturaDisco: 280,
      mostrarEnlacesCompletos: true,
      mostrarPieMetadata: true,
    );
  }
}
