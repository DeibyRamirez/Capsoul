import 'package:flutter/material.dart';

import '../tema/colores_app.dart';

/// Cabecera de pestaña: marca cápsoul, título + icono y subtítulo.
class EncabezadoSeccionCapsoul extends StatelessWidget {
  const EncabezadoSeccionCapsoul({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    this.iconoTitulo,
    this.heroTag,
    this.mostrarMarca = true,
    this.acciones,
    this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 4),
  });

  final String titulo;
  final String subtitulo;
  final IconData icono;
  final Widget? iconoTitulo;
  final String? heroTag;
  final bool mostrarMarca;
  final Widget? acciones;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    final iconoTitulo = this.iconoTitulo;
    final heroTag = this.heroTag;
    Widget iconoSeccion = Icon(icono, color: ColoresApp.acento, size: 28);
    if (heroTag != null) {
      iconoSeccion = Hero(
        tag: heroTag,
        child: Material(type: MaterialType.transparency, child: iconoSeccion),
      );
    }
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (mostrarMarca)
            Text(
              'cápsoul',
              style: estilos.labelLarge?.copyWith(
                color: ColoresApp.acento,
                fontWeight: FontWeight.w600,
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (iconoTitulo != null) ...[
                      iconoTitulo,
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        titulo,
                        style: estilos.headlineMedium?.copyWith(
                          color: ColoresApp.primario,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    iconoSeccion,
                  ],
                ),
              ),
              ?acciones,
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitulo,
            style: estilos.bodyMedium?.copyWith(color: ColoresApp.atenuado),
          ),
        ],
      ),
    );
  }
}
