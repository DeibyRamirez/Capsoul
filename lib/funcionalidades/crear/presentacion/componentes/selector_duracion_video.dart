import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tema/tokens_crear.dart';

/// Chips de duración máxima del video.
class SelectorDuracionVideo extends StatelessWidget {
  const SelectorDuracionVideo({
    super.key,
    required this.opciones,
    required this.seleccionada,
    required this.alCambiar,
    this.oculto = false,
  });

  final List<Duration> opciones;
  final Duration seleccionada;
  final ValueChanged<Duration> alCambiar;
  final bool oculto;

  @override
  Widget build(BuildContext context) {
    if (oculto) return const SizedBox.shrink();
    final tokens = tokensCrearDe(context);
    return AnimatedOpacity(
      opacity: oculto ? 0 : 1,
      duration: duracionMotionCrear(context, const Duration(milliseconds: 200)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final duracion in opciones)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(_etiqueta(duracion)),
                selected: duracion == seleccionada,
                onSelected: (_) {
                  HapticFeedback.selectionClick();
                  alCambiar(duracion);
                },
                labelStyle: TextStyle(
                  color: duracion == seleccionada
                      ? tokens.marcaPrimario
                      : tokens.superficieCamara,
                  fontWeight: FontWeight.w600,
                  shadows: duracion == seleccionada
                      ? null
                      : const [Shadow(blurRadius: 4, color: Colors.black54)],
                ),
                selectedColor: tokens.sobreMarca,
                backgroundColor: Colors.black26,
                side: BorderSide.none,
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
    );
  }

  String _etiqueta(Duration d) {
    if (d.inSeconds < 60) return '${d.inSeconds} s';
    return '${d.inMinutes} min';
  }
}
