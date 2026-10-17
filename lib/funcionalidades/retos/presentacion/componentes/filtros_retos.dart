import 'package:flutter/material.dart';

import '../../../../nucleo/componentes/pildoras_seleccion_capsoul.dart';

enum FiltroRetosTab { activos, completados, favoritos }

class FiltrosRetos extends StatelessWidget {
  const FiltrosRetos({
    super.key,
    required this.seleccionado,
    required this.alCambiar,
  });

  final FiltroRetosTab seleccionado;
  final ValueChanged<FiltroRetosTab> alCambiar;

  static String _etiqueta(FiltroRetosTab tab) => switch (tab) {
        FiltroRetosTab.activos => 'Activos',
        FiltroRetosTab.completados => 'Completados',
        FiltroRetosTab.favoritos => 'Favoritos',
      };

  @override
  Widget build(BuildContext context) {
    return PildorasSeleccionCapsoul<FiltroRetosTab>(
      opciones: FiltroRetosTab.values,
      seleccionado: seleccionado,
      alCambiar: alCambiar,
      etiqueta: _etiqueta,
    );
  }
}
