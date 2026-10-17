import 'package:flutter/material.dart';

import '../../../../nucleo/tema/colores_app.dart';

class EstadoVacioRetos extends StatelessWidget {
  const EstadoVacioRetos({
    super.key,
    required this.mensaje,
    this.icono = Icons.inbox_outlined,
  });

  final String mensaje;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icono, size: 48, color: ColoresApp.atenuado),
          const SizedBox(height: 16),
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: estilos.bodyLarge?.copyWith(color: ColoresApp.textoSecundario),
          ),
        ],
      ),
    );
  }
}
