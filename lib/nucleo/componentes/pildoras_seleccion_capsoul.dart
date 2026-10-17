import 'package:flutter/material.dart';

import '../tema/colores_app.dart';

/// Fila de píldoras con una opción activa (estilo Activos/Completados).
class PildorasSeleccionCapsoul<T> extends StatelessWidget {
  const PildorasSeleccionCapsoul({
    super.key,
    required this.opciones,
    required this.seleccionado,
    required this.alCambiar,
    required this.etiqueta,
  });

  final List<T> opciones;
  final T seleccionado;
  final ValueChanged<T> alCambiar;
  final String Function(T valor) etiqueta;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final opcion in opciones)
          _Pildora(
            texto: etiqueta(opcion),
            activa: opcion == seleccionado,
            estilos: estilos,
            onTap: () => alCambiar(opcion),
          ),
      ],
    );
  }
}

class _Pildora extends StatelessWidget {
  const _Pildora({
    required this.texto,
    required this.activa,
    required this.estilos,
    required this.onTap,
  });

  final String texto;
  final bool activa;
  final TextTheme estilos;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: activa ? ColoresApp.primario : ColoresApp.tarjeta,
      shape: StadiumBorder(
        side: BorderSide(
          color: activa ? ColoresApp.primario : ColoresApp.bordeTarjeta,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Text(
            texto,
            style: estilos.labelLarge?.copyWith(
              color: activa
                  ? ColoresApp.sobrePrimario
                  : ColoresApp.textoSecundario,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
