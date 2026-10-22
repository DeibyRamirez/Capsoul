import 'package:flutter/material.dart';

import '../../../../nucleo/tema/colores_app.dart';
import '../../../../nucleo/tema/tipografia_app.dart';

/// Encabezado de marca de Capsoul: frasco luminoso, nombre y eslogan.
class EncabezadoAutenticacion extends StatelessWidget {
  const EncabezadoAutenticacion({super.key, this.subtitulo});

  final String? subtitulo;

  @override
  Widget build(BuildContext context) {
    final estilosTexto = Theme.of(context).textTheme;
    final subtitulo = this.subtitulo;
    return Column(
      children: [
        Text(
          'Capsoul',
          style: estilosTexto.headlineMedium?.copyWith(
            color: ColoresApp.primario,
            fontFamily: TipografiaApp.fuenteTitulos,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Pequeñas herencias, grandes recuerdos',
          textAlign: TextAlign.center,
          style: estilosTexto.bodyMedium?.copyWith(
            color: ColoresApp.textoSecundario,
            fontStyle: FontStyle.italic,
          ),
        ),
        if (subtitulo != null) ...[
          const SizedBox(height: 16),
          Text(
            subtitulo,
            textAlign: TextAlign.center,
            style: estilosTexto.bodyLarge?.copyWith(color: ColoresApp.atenuado),
          ),
        ],
      ],
    );
  }
}
