import 'package:flutter/material.dart';

import '../tema/colores_app.dart';
import '../tema/espaciado_app.dart';
import '../tema/tema_app.dart';
import '../tema/tipografia_app.dart';

/// Tarjeta blanca reutilizable (borde sutil, sombra azul suave, radio 20)
/// con chip de icono y contenido flexible.
class TarjetaCapsoul extends StatelessWidget {
  const TarjetaCapsoul({
    super.key,
    this.icono,
    this.titulo,
    required this.child,
    this.alTocar,
    this.altoMinimo,
    this.radio = TemaApp.radioGrande,
    this.borde = true,
    this.conSombra = false,
  });

  final IconData? icono;
  final String? titulo;
  final Widget child;
  final VoidCallback? alTocar;
  final double? altoMinimo;
  final double radio;
  final bool borde;

  /// Sombra solo en piezas hero. En listas queda en falso para no difuminar.
  final bool conSombra;

  @override
  Widget build(BuildContext context) {
    final decoracion = borde
        ? BoxDecoration(
            border: Border.all(color: ColoresApp.bordeTarjeta),
            borderRadius: BorderRadius.circular(radio),
          )
        : null;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radio),
        boxShadow: conSombra ? TemaApp.sombraTarjeta : null,
      ),
      child: Material(
        color: ColoresApp.tarjeta,
        borderRadius: BorderRadius.circular(radio),
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: alTocar,
          child: Container(
            decoration: decoracion,
            constraints: altoMinimo != null
                ? BoxConstraints(minHeight: altoMinimo!)
                : null,
            child: Padding(
              padding: const EdgeInsets.all(EspaciadoApp.md),
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
                              color: ColoresApp.primario.withValues(
                                alpha: 0.08,
                              ),
                              borderRadius: BorderRadius.circular(
                                TemaApp.radioPequeno,
                              ),
                            ),
                            child: Icon(
                              icono,
                              size: 24,
                              color: ColoresApp.primario,
                            ),
                          ),
                        if (icono != null && titulo != null)
                          const SizedBox(width: 8),
                        if (titulo != null)
                          Expanded(
                            child: Text(
                              titulo!,
                              style: TipografiaApp.tituloPequeno,
                            ),
                          ),
                      ],
                    ),
                  if (icono != null || titulo != null)
                    const SizedBox(height: 6),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
