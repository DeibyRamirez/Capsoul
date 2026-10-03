import 'package:flutter/material.dart';

import '../../../../nucleo/formato/fechas.dart';
import '../../../../nucleo/tema/colores_app.dart';
import '../../../../nucleo/tema/tema_app.dart';
import '../../../recuerdos/presentacion/componentes/miniatura_recuerdo_firmada.dart';
import '../../dominio/momento.dart';

/// Tarjeta de un momento: portada, nombre y "N recuerdos · fecha".
class TarjetaMomento extends StatelessWidget {
  const TarjetaMomento({super.key, required this.momento, required this.alTocar});

  final Momento momento;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final portada = momento.portada;
    final cantidad = momento.cantidad;
    final detalle = '${cantidad == 1 ? '1 recuerdo' : '$cantidad recuerdos'}'
        ' · ${formatearFechaCorta(momento.creadoEn.toLocal())}';
    return Semantics(
      button: true,
      label: 'Momento: ${momento.titulo}',
      child: Material(
        color: ColoresApp.sobrePrimario,
        borderRadius: BorderRadius.circular(TemaApp.radioMediano),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: alTocar,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: portada == null
                    ? const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [ColoresApp.acento, ColoresApp.primario],
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.auto_awesome_mosaic_outlined,
                            color: ColoresApp.sobrePrimario,
                            size: 36,
                          ),
                        ),
                      )
                    : MiniaturaRecuerdoFirmada(recuerdo: portada),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      momento.titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: ColoresApp.primario,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detalle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: ColoresApp.atenuado,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
