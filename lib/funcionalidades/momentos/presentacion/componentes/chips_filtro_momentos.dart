import 'package:flutter/material.dart';

import '../../../../nucleo/tema/colores_app.dart';
import '../../../../nucleo/tema/tema_app.dart';
import '../../../elementos/dominio/tipo_elemento.dart';

/// Chips de filtro por tipo de portada del momento.
class ChipsFiltroMomentos extends StatelessWidget {
  const ChipsFiltroMomentos({
    super.key,
    required this.tipoSeleccionado,
    required this.alCambiar,
  });

  final TipoElemento? tipoSeleccionado;
  final ValueChanged<TipoElemento?> alCambiar;

  static const _opciones = <({String etiqueta, TipoElemento? tipo})>[
    (etiqueta: 'Todos', tipo: null),
    (etiqueta: 'Fotos', tipo: TipoElemento.foto),
    (etiqueta: 'Videos', tipo: TipoElemento.video),
    (etiqueta: 'Audios', tipo: TipoElemento.audio),
    (etiqueta: 'Cartas', tipo: TipoElemento.texto),
    (etiqueta: 'Música', tipo: TipoElemento.musica),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final opcion in _opciones)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(opcion.etiqueta),
                selected: tipoSeleccionado == opcion.tipo,
                showCheckmark: false,
                onSelected: (_) => alCambiar(opcion.tipo),
                selectedColor: ColoresApp.primario,
                labelStyle: TextStyle(
                  color: tipoSeleccionado == opcion.tipo
                      ? ColoresApp.sobrePrimario
                      : ColoresApp.primario,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(TemaApp.radioGrande),
                  side: BorderSide(
                    color: tipoSeleccionado == opcion.tipo
                        ? ColoresApp.primario
                        : ColoresApp.atenuado.withValues(alpha: 0.4),
                  ),
                ),
                backgroundColor: ColoresApp.sobrePrimario,
              ),
            ),
        ],
      ),
    );
  }
}
