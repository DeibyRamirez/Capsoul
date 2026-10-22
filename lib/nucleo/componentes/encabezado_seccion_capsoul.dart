import 'package:flutter/material.dart';

import '../tema/colores_app.dart';
import '../tema/espaciado_app.dart';
import '../tema/tipografia_app.dart';

/// Cabecera de pestaña: marca cápsoul, título + icono y subtítulo.
class EncabezadoSeccionCapsoul extends StatelessWidget {
  const EncabezadoSeccionCapsoul({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    this.iconoTitulo,
    this.mostrarMarca = true,
    this.acciones,
    this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 4),
  });

  final String titulo;
  final String subtitulo;
  final IconData icono;
  final Widget? iconoTitulo;
  final bool mostrarMarca;
  final Widget? acciones;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (mostrarMarca)
            const Text(
              'cápsoul',
              style: TextStyle(
                fontFamily: TipografiaApp.fuenteUi,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: ColoresApp.acento,
                letterSpacing: 1.1,
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (iconoTitulo != null) ...[
                      iconoTitulo!,
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        titulo,
                        style: TipografiaApp.titular,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      icono,
                      color: ColoresApp.acento,
                      size: 28,
                    ),
                  ],
                ),
              ),
              ?acciones,
            ],
          ),
          const SizedBox(height: EspaciadoApp.xxs),
          Text(subtitulo, style: TipografiaApp.cuerpoPequeno),
        ],
      ),
    );
  }
}
