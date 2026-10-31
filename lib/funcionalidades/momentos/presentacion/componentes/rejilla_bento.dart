import 'package:flutter/material.dart';

import '../../../../nucleo/tema/colores_app.dart';
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
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(TemaApp.radioMediano),
                        boxShadow: TemaApp.sombraTarjeta,
                        border: Border.all(
                          color: ColoresApp.vidrioCupula.withValues(alpha: 0.35),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(TemaApp.radioMediano),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => alTocar(c.recuerdo),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                MiniaturaRecuerdoFirmada(recuerdo: c.recuerdo),
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 0,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          ColoresApp.medianoche
                                              .withValues(alpha: 0.75),
                                        ],
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        8,
                                        20,
                                        8,
                                        8,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            c.recuerdo.tipo.etiqueta,
                                            style: const TextStyle(
                                              color: ColoresApp.acento,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.4,
                                            ),
                                          ),
                                          Text(
                                            c.recuerdo.nombre,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: ColoresApp.sobrePrimario,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
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
