import 'package:flutter/material.dart';

import '../tema/colores_app.dart';
import '../tema/tema_app.dart';

/// Tarjeta blanca reutilizable con chip de icono y contenido flexible.
class TarjetaCapsoul extends StatelessWidget {
  const TarjetaCapsoul({
    super.key,
    this.icono,
    this.titulo,
    required this.child,
    this.alTocar,
    this.altoMinimo,
    this.radio = TemaApp.radioGrande,
    this.borde = false,
  });

  final IconData? icono;
  final String? titulo;
  final Widget child;
  final VoidCallback? alTocar;
  final double? altoMinimo;
  final double radio;
  final bool borde;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    final decoracion = borde
        ? BoxDecoration(
            border: Border.all(
              color: ColoresApp.atenuado.withValues(alpha: 0.12),
            ),
            borderRadius: BorderRadius.circular(radio),
          )
        : null;

    return Material(
      color: ColoresApp.sobrePrimario,
      borderRadius: BorderRadius.circular(radio),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: alTocar,
        child: Container(
          decoration: decoracion,
          constraints: altoMinimo != null
              ? BoxConstraints(minHeight: altoMinimo!)
              : null,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (icono != null || titulo != null)
                  Row(
                    children: [
                      if (icono != null)
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: ColoresApp.primario,
                            borderRadius:
                                BorderRadius.circular(TemaApp.radioPequeno),
                          ),
                          child: Icon(
                            icono,
                            size: 18,
                            color: ColoresApp.sobrePrimario,
                          ),
                        ),
                      if (icono != null && titulo != null)
                        const SizedBox(width: 8),
                      if (titulo != null)
                        Expanded(
                          child: Text(
                            titulo!,
                            style: estilos.titleSmall?.copyWith(
                              color: ColoresApp.primario,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                if (icono != null || titulo != null) const SizedBox(height: 6),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
