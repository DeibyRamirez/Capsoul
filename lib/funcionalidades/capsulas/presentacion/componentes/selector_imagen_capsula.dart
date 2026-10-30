import 'package:flutter/material.dart';

import '../../../../nucleo/tema/colores_app.dart';
import '../../../../nucleo/tema/tema_app.dart';
import '../../dominio/imagen_capsula.dart';

/// Grilla para elegir la imagen local de la capsula.
class SelectorImagenCapsula extends StatelessWidget {
  const SelectorImagenCapsula({
    super.key,
    required this.seleccionada,
    required this.alElegir,
    this.deshabilitado = false,
  });

  final String? seleccionada;
  final ValueChanged<String> alElegir;
  final bool deshabilitado;

  @override
  Widget build(BuildContext context) {
    final activa = ImagenCapsula.desdeClave(seleccionada);
    return GridView.builder(
      key: const Key('selector-imagen-capsula'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: ImagenCapsula.values.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 3 / 4,
      ),
      itemBuilder: (context, indice) {
        final imagen = ImagenCapsula.values[indice];
        final elegida = imagen == activa;
        final radio = BorderRadius.circular(TemaApp.radioGrande / 2);
        return Semantics(
          button: true,
          selected: elegida,
          label: imagen.nombre,
          child: InkWell(
            key: Key('opcion-imagen-${imagen.clave}'),
            borderRadius: radio,
            onTap: deshabilitado ? null : () => alElegir(imagen.clave),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                borderRadius: radio,
                border: Border.all(
                  color: elegida ? ColoresApp.primario : ColoresApp.bordeTarjeta,
                  width: elegida ? 3 : 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: radio,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      imagen.ruta,
                      fit: BoxFit.cover,
                      cacheWidth: 240,
                      errorBuilder: (_, _, _) =>
                          const ColoredBox(color: ColoresApp.fondoInicio),
                    ),
                    if (elegida)
                      const Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.check_circle,
                            size: 20,
                            color: ColoresApp.primario,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
