import 'package:flutter/material.dart';

import '../../../../nucleo/tema/colores_app.dart';

/// Encabezado de marca de Capsoul: cúpula pequeña, nombre y eslogan.
class EncabezadoAutenticacion extends StatelessWidget {
  const EncabezadoAutenticacion({super.key, this.subtitulo});

  final String? subtitulo;

  @override
  Widget build(BuildContext context) {
    final estilosTexto = Theme.of(context).textTheme;
    final subtitulo = this.subtitulo;
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                ColoresApp.acento.withValues(alpha: 0.6),
                ColoresApp.primario,
              ],
            ),
            border: Border.all(color: ColoresApp.bordeCupula, width: 2),
            boxShadow: [
              BoxShadow(
                color: ColoresApp.primario.withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.auto_awesome,
            color: ColoresApp.sobrePrimario,
            size: 40,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Capsoul',
          style: estilosTexto.headlineMedium?.copyWith(
            color: ColoresApp.primario,
            fontWeight: FontWeight.w700,
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
