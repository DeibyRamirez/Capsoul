import 'package:flutter/material.dart';

import '../../../../nucleo/componentes/frasco_luminoso.dart';
import '../../../../nucleo/tema/colores_app.dart';

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
        const FrascoLuminoso(tamano: 88, brillo: 0.85, conRecuerdos: false),
        const SizedBox(height: 16),
        Text(
          'Capsoul',
          style: estilosTexto.headlineMedium?.copyWith(
            color: ColoresApp.primario,
            fontFamily: 'serif',
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Pequeñas herencias, grandes recuerdos',
          textAlign: TextAlign.center,
          style: estilosTexto.bodyMedium?.copyWith(
            color: ColoresApp.acento,
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
