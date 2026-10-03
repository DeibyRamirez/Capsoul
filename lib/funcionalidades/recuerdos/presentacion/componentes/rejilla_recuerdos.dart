import 'package:flutter/material.dart';

import '../../dominio/recuerdo.dart';
import 'tarjeta_recuerdo.dart';

/// Rejilla de dos columnas de [TarjetaRecuerdo] (como sliver).
class RejillaRecuerdos extends StatelessWidget {
  const RejillaRecuerdos({
    super.key,
    required this.recuerdos,
    required this.alTocar,
    this.seleccionados,
  });

  final List<Recuerdo> recuerdos;
  final ValueChanged<Recuerdo> alTocar;

  /// Ids marcados; `null` si la rejilla no es de selección.
  final Set<String>? seleccionados;

  @override
  Widget build(BuildContext context) {
    final marcados = seleccionados;
    final escala = MediaQuery.textScalerOf(context).scale(1);
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      sliver: SliverLayoutBuilder(
        builder: (context, restricciones) {
          final ancho = (restricciones.crossAxisExtent - _separacion) / 2;
          return SliverGrid.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: _separacion,
          crossAxisSpacing: _separacion,
          // Cuadrado de la miniatura + dos líneas de texto.
          mainAxisExtent: ancho + _altoTexto * escala,
        ),
        itemCount: recuerdos.length,
        itemBuilder: (context, indice) {
          final recuerdo = recuerdos[indice];
          return TarjetaRecuerdo(
            key: ValueKey(recuerdo.id),
            recuerdo: recuerdo,
            seleccionado: marcados?.contains(recuerdo.id),
            alTocar: () => alTocar(recuerdo),
          );
        },
          );
        },
      ),
    );
  }

  static const double _separacion = 12;
  static const double _altoTexto = 64;
}

/// Mensaje centrado cuando no hay recuerdos (como sliver).
class SinRecuerdos extends StatelessWidget {
  const SinRecuerdos({super.key, required this.mensaje, this.accion});

  final String mensaje;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    final boton = accion;
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(mensaje, textAlign: TextAlign.center),
            if (boton != null) ...[const SizedBox(height: 16), boton],
          ],
        ),
      ),
    );
  }
}
