import 'package:flutter/material.dart';

import '../../../../nucleo/tema/colores_app.dart';
import '../../../../nucleo/tema/tema_app.dart';
import '../../dominio/imagen_capsula.dart';

/// Imagen local de la capsula (tarjetas de "Mis capsulas"). Si la clave
/// es nula o desconocida usa [ImagenCapsula.porDefecto].
class MiniaturaImagenCapsula extends StatelessWidget {
  const MiniaturaImagenCapsula({
    super.key,
    required this.imagenClave,
    this.ancho = 60,
    this.conCandado = false,
    this.atenuada = false,
  });

  final String? imagenClave;
  final double ancho;
  final bool conCandado;
  final bool atenuada;

  @override
  Widget build(BuildContext context) {
    final imagen = ImagenCapsula.desdeClave(imagenClave);
    final alto = ancho * 4 / 3;
    return Semantics(
      label: 'Imagen de la capsula: ${imagen.nombre}',
      image: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(TemaApp.radioGrande / 2),
        child: SizedBox(
          width: ancho,
          height: alto,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Opacity(
                opacity: atenuada ? 0.75 : 1,
                child: Image.asset(
                  imagen.ruta,
                  key: ValueKey('imagen-capsula-${imagen.clave}'),
                  fit: BoxFit.cover,
                  cacheWidth: (ancho * 3).round(),
                  errorBuilder: (_, _, _) =>
                      const ColoredBox(color: ColoresApp.fondoInicio),
                ),
              ),
              if (conCandado)
                const Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: EdgeInsets.all(4),
                    child: CircleAvatar(
                      radius: 10,
                      backgroundColor: ColoresApp.tarjeta,
                      child: Icon(
                        Icons.lock_rounded,
                        size: 13,
                        color: ColoresApp.primario,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
