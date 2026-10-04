import 'package:flutter/material.dart';

import '../tema/colores_app.dart';
import '../tema/degradados_capsoul.dart';
import 'cielo_nocturno.dart';

/// Nivel de fondo de una pantalla Capsoul.
enum FondoCapsoulTipo { suave, nocturno, plano }

/// Envoltorio de degradado (y opcionalmente cielo animado) para el cuerpo.
class FondoCapsoul extends StatelessWidget {
  const FondoCapsoul({
    super.key,
    required this.tipo,
    this.conCieloAnimado = false,
    this.brilloCielo = 1,
    required this.child,
  });

  final FondoCapsoulTipo tipo;
  final bool conCieloAnimado;
  final double brilloCielo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (tipo == FondoCapsoulTipo.nocturno || conCieloAnimado) {
      return CieloNocturno(
        brillo: brilloCielo,
        animado: conCieloAnimado || tipo == FondoCapsoulTipo.nocturno,
        child: child,
      );
    }

    final decoracion = switch (tipo) {
      FondoCapsoulTipo.suave => const BoxDecoration(
          gradient: DegradadosCapsoul.suave,
        ),
      FondoCapsoulTipo.plano => const BoxDecoration(
          color: ColoresApp.superficie,
        ),
      FondoCapsoulTipo.nocturno => const BoxDecoration(
          gradient: DegradadosCapsoul.nocturno,
        ),
    };

    return DecoratedBox(decoration: decoracion, child: child);
  }
}
