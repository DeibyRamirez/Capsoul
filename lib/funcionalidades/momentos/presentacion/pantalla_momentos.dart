import 'package:flutter/material.dart';

import '../../../nucleo/tema/colores_app.dart';

/// Pestaña "Momentos" (marcador del Sprint 1).
class PantallaMomentos extends StatelessWidget {
  const PantallaMomentos({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Momentos')),
      body: Center(
        child: Text(
          'Tus momentos aparecerán aquí',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: ColoresApp.atenuado,
              ),
        ),
      ),
    );
  }
}
