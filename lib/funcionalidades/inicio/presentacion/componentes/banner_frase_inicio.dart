import 'package:flutter/material.dart';

import '../../../../nucleo/componentes/frasco_luminoso.dart';
import '../../../../nucleo/tema/colores_app.dart';
import '../../../../nucleo/tema/tema_app.dart';

/// Banner azul marino con la frase de Capsoul.
class BannerFraseInicio extends StatelessWidget {
  const BannerFraseInicio({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 10, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(TemaApp.radioGrande),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [ColoresApp.primario, ColoresApp.acento],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'No se trata de tener más tiempo, sino de dejar lo que importa.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ColoresApp.sobrePrimario,
                    height: 1.4,
                  ),
            ),
          ),
          const SizedBox(width: 8),
          const FrascoLuminoso(tamano: 64, brillo: 1),
        ],
      ),
    );
  }
}
