import 'package:flutter/material.dart';

import 'pantalla_mis_capsulas.dart';
import 'vista_capsulas_tab.dart';

/// Cápsulas enviadas a este usuario como destinatario (misma UI que Mis cápsulas).
class PantallaCapsulasRecibidas extends StatelessWidget {
  const PantallaCapsulasRecibidas({super.key});

  @override
  Widget build(BuildContext context) {
    return const PantallaMisCapsulas(
      vistaInicial: VistaCapsulasTab.paraMi,
    );
  }
}
