import 'package:flutter/material.dart';

import '../../../../nucleo/componentes/cielo_nocturno.dart';
import '../../../../nucleo/tema/colores_app.dart';
import '../../../../nucleo/tema/tema_app.dart';

/// Diseño centrado y desplazable compartido por las pantallas de
/// autenticación, sobre cielo nocturno animado.
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
              foregroundColor: ColoresApp.sobrePrimario,
              elevation: 0,
            )
          : null,
      body: CieloNocturno(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Material(
                  color: ColoresApp.sobrePrimario.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(TemaApp.radioGrande),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: contenido,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
