import 'package:flutter/material.dart';

import '../../../nucleo/tema/colores_app.dart';

/// Pestaña "Mi legado" (marcador del Sprint 1).
class PantallaLegado extends StatelessWidget {
  const PantallaLegado({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi legado')),
      body: Center(
        child: Text(
          'Tu legado se construye día a día',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: ColoresApp.atenuado,
              ),
        ),
      ),
    );
  }
}
