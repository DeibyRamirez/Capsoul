import 'package:flutter/material.dart';

import '../../../../nucleo/componentes/frasco_luminoso.dart';
import '../../../../nucleo/tema/colores_app.dart';

/// La cápsula de vidrio iluminada con recuerdos dentro y el texto
/// manuscrito "Tu vida. Tus momentos. Tu legado.".
class EscenaFrascoInicio extends StatelessWidget {
  const EscenaFrascoInicio({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 270,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 8,
            child: Container(
              width: 240,
              height: 28,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.elliptical(240, 28)),
                gradient: RadialGradient(
                  colors: [
                    ColoresApp.acento.withValues(alpha: 0.35),
                    ColoresApp.acento.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          const FrascoLuminoso(
            tamano: 250,
            brillo: 0.9,
            conRecuerdos: true,
            conCandado: true,
          ),
          const Positioned(right: 4, top: 70, child: _TextoManuscrito()),
        ],
      ),
    );
  }
}

class _TextoManuscrito extends StatelessWidget {
  const _TextoManuscrito();

  @override
  Widget build(BuildContext context) {
    final estilo = Theme.of(context).textTheme.titleMedium?.copyWith(
          color: ColoresApp.sobrePrimario.withValues(alpha: 0.95),
          fontStyle: FontStyle.italic,
          fontFamily: 'serif',
          fontWeight: FontWeight.w300,
          height: 1.5,
          shadows: const [
            Shadow(
              blurRadius: 4,
              color: Color(0x40000000),
            ),
          ],
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tu vida.', style: estilo),
        Text('Tus momentos.', style: estilo),
        Text('Tu legado.', style: estilo),
        const SizedBox(height: 4),
        Icon(
          Icons.favorite_border,
          size: 16,
          color: ColoresApp.sobrePrimario.withValues(alpha: 0.8),
        ),
      ],
    );
  }
}
