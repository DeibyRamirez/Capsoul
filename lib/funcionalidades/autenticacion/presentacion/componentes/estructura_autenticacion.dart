import 'package:flutter/material.dart';

import '../../../../nucleo/tema/colores_app.dart';

/// Diseño centrado y desplazable compartido por las pantallas de
/// autenticación.
class EstructuraAutenticacion extends StatelessWidget {
  const EstructuraAutenticacion({
    super.key,
    required this.contenido,
    this.mostrarAtras = false,
  });

  final Widget contenido;
  final bool mostrarAtras;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: mostrarAtras
          ? AppBar(
              backgroundColor: ColoresApp.superficie,
              foregroundColor: ColoresApp.primario,
            )
          : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: contenido,
            ),
          ),
        ),
      ),
    );
  }
}
