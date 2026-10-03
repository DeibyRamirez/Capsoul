import 'package:flutter/material.dart';

import '../../../../nucleo/tema/colores_app.dart';
import '../../../../nucleo/tema/tema_app.dart';
import '../../../elementos/dominio/tipo_elemento.dart';
import '../../dominio/recuerdo.dart';
import 'miniatura_recuerdo_firmada.dart';
import 'reproductores_medio.dart';

/// Contenido completo de un recuerdo: foto, reproductor de video o de audio,
/// o el texto de la nota.
class VistaRecuerdo extends StatelessWidget {
  const VistaRecuerdo({super.key, required this.recuerdo});

  final Recuerdo recuerdo;

  @override
  Widget build(BuildContext context) {
    return switch (recuerdo.tipo) {
      TipoElemento.texto => Card(
          color: ColoresApp.sobrePrimario,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SelectableText(
              recuerdo.contenidoTexto ?? '',
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ),
        ),
      TipoElemento.foto => ClipRRect(
          borderRadius: BorderRadius.circular(TemaApp.radioGrande),
          child: FotoCompleta(recuerdo: recuerdo),
        ),
      TipoElemento.video => ClipRRect(
          borderRadius: BorderRadius.circular(TemaApp.radioGrande),
          child: ReproductorVideoRecuerdo(recuerdo: recuerdo),
        ),
      TipoElemento.audio => ReproductorAudioRecuerdo(recuerdo: recuerdo),
    };
  }
}

/// Miniatura de respaldo con proporción 4:3 (mientras carga o sin medio).
class MarcoMiniatura extends StatelessWidget {
  const MarcoMiniatura({super.key, required this.recuerdo});

  final Recuerdo recuerdo;

  @override
  Widget build(BuildContext context) => AspectRatio(
        aspectRatio: 4 / 3,
        child: MiniaturaRecuerdoFirmada(recuerdo: recuerdo, tamanoIcono: 48),
      );
}
