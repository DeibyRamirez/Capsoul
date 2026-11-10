import 'package:flutter/material.dart';

import '../tema/tokens_crear.dart';

/// Gradientes superior e inferior sobre el preview de cámara (contraste AA).
class ScrimCamara extends StatelessWidget {
  const ScrimCamara({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = tokensCrearDe(context);
    final scrim = tokens.colorScrim;
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  scrim.withValues(alpha: tokens.opacidadScrimSuperior),
                  scrim.withValues(alpha: 0),
                ],
                stops: const [0, 0.28],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              height: 280,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      scrim.withValues(alpha: tokens.opacidadScrimInferior),
                      scrim.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
