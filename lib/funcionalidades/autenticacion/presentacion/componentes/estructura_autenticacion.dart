import 'package:flutter/material.dart';

import '../../../../nucleo/componentes/cielo_nocturno.dart';
import '../../../../nucleo/tema/colores_app.dart';
import '../../../../nucleo/tema/degradados_capsoul.dart';
import '../../../../nucleo/tema/tema_app.dart';

/// Diseño centrado y desplazable compartido por las pantallas de
/// autenticación: fondo claro, banner medianoche con luciernagas y panel
/// blanco con el formulario.
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
      extendBodyBehindAppBar: mostrarAtras,
      appBar: mostrarAtras
          ? AppBar(
              backgroundColor: Colors.transparent,
              foregroundColor: ColoresApp.textoPrincipal,
              elevation: 0,
            )
          : null,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: DegradadosCapsoul.suave),
        child: Stack(
          children: [
            // Banda medianoche con luciernagas detras del panel (no ocupa
            // alto en el flujo del formulario).
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 220,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(TemaApp.radioGrande),
                ),
                child: const CieloNocturno(),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: DecoratedBox(
                      decoration: TemaApp.decoracionTarjeta(),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: contenido,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
