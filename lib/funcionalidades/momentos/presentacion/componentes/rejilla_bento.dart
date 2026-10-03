import 'package:flutter/material.dart';

import '../../../../nucleo/tema/tema_app.dart';
import '../../../recuerdos/dominio/recuerdo.dart';
import '../../../recuerdos/presentacion/componentes/miniatura_recuerdo_firmada.dart';
import '../../dominio/distribucion_bento.dart';

/// Rejilla bento de 4 columnas con los recuerdos del momento.
class RejillaBento extends StatelessWidget {
  const RejillaBento({super.key, required this.recuerdos, required this.alTocar});

  final List<Recuerdo> recuerdos;
  final ValueChanged<Recuerdo> alTocar;

  static const double _separacion = 8;

  @override
  Widget build(BuildContext context) {
    final distribucion = distribuirBento(recuerdos);
    return LayoutBuilder(
      builder: (context, restricciones) {
        final celda = (restricciones.maxWidth -
                _separacion * (columnasBento - 1)) /
            columnasBento;
        double medida(int celdas) => celda * celdas + _separacion * (celdas - 1);
        final paso = celda + _separacion;
        return SizedBox(
          height: distribucion.filas == 0
              ? 0
              : paso * distribucion.filas - _separacion,
          child: Stack(
            children: [
              for (final c in distribucion.celdas)
                Positioned(
                  key: ValueKey(c.recuerdo.id),
                  left: c.columna * paso,
                  top: c.fila * paso,
                  width: medida(c.ancho),
                  height: medida(c.alto),
                  child: Semantics(
                    button: true,
                    label: '${c.recuerdo.tipo.etiqueta}: ${c.recuerdo.nombre}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(TemaApp.radioMediano),
                      child: Material(
                        child: InkWell(
                          onTap: () => alTocar(c.recuerdo),
                          child: MiniaturaRecuerdoFirmada(recuerdo: c.recuerdo),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
