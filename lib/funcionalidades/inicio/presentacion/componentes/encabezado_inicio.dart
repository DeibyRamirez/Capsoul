import 'package:flutter/material.dart';

import '../../../../nucleo/tema/colores_app.dart';
import '../../../../nucleo/tema/tema_app.dart';

/// Logo "cápsoul", slogan y campana de avisos.
class EncabezadoInicio extends StatelessWidget {
  const EncabezadoInicio({
    super.key,
    required this.alTocarCampana,
    this.textoBadge,
  });

  final VoidCallback alTocarCampana;

  /// `null` oculta el contador. Más de 9 llega ya como «9+».
  final String? textoBadge;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    return Row(
      children: [
        const SizedBox(width: 48),
        Expanded(
          child: Column(
            children: [
              Text(
                'cápsoul',
                style: estilos.headlineMedium?.copyWith(
                  color: ColoresApp.primario,
                  fontFamily: TemaApp.fuenteTitulos,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                'Pequeñas herencias, grandes recuerdos',
                textAlign: TextAlign.center,
                style: estilos.bodySmall?.copyWith(
                  color: ColoresApp.textoSecundario,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: textoBadge == null ? 'Avisos' : 'Avisos, $textoBadge nuevos',
          onPressed: alTocarCampana,
          color: ColoresApp.primario,
          icon: Badge(
            isLabelVisible: textoBadge != null,
            backgroundColor: ColoresApp.acento,
            textColor: ColoresApp.sobrePrimario,
            label: textoBadge == null
                ? null
                : Text(textoBadge!, key: const Key('texto-badge-avisos')),
            child: const Icon(Icons.notifications_none_outlined),
          ),
        ),
      ],
    );
  }
}
