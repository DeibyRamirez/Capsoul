import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../nucleo/tema/colores_app.dart';

/// Crédito obligatorio de Deezer (logo + texto), visible donde se usa su API.
class CreditoDeezer extends StatelessWidget {
  const CreditoDeezer({super.key, this.color, this.mostrarUsoPersonal = false});

  final Color? color;

  /// Añade la nota de uso personal que piden los términos de la API.
  final bool mostrarUsoPersonal;

  @override
  Widget build(BuildContext context) {
    final tono = color ?? ColoresApp.textoSecundario;
    final estilo = Theme.of(context)
        .textTheme
        .labelMedium
        ?.copyWith(color: tono, fontWeight: FontWeight.w600);
    return Semantics(
      label: 'Música de Deezer',
      container: true,
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(FontAwesomeIcons.deezer, size: 16, color: tono),
              const SizedBox(width: 6),
              Text('Música de Deezer', style: estilo),
            ],
          ),
          if (mostrarUsoPersonal)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Vistas previas de 30 s, solo para uso personal.',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: tono, fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }
}
