import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../nucleo/enrutador/rutas_app.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../../../nucleo/tema/tema_app.dart';

/// Contenedor con la barra inferior: Inicio | Momentos | + | Mi legado | Yo.
/// El `+` central abre Crear (no es una rama persistente del shell).
class ContenedorNavegacion extends StatelessWidget {
  const ContenedorNavegacion({super.key, required this.navegacionRamas});

  /// Shell de go_router que conserva el estado de cada pestaña.
  final StatefulNavigationShell navegacionRamas;

  /// Posición del botón `+` en la barra.
  static const int _posicionCrear = 2;

  int get _posicionSeleccionada {
    // Las ramas 0..3 corresponden a las posiciones 0, 1, 3 y 4 de la barra
    // (la posición 2 es Crear).
    return switch (navegacionRamas.currentIndex) {
      0 => 0,
      1 => 1,
      2 => 3,
      3 => 4,
      _ => 0,
    };
  }

  void _alSeleccionarDestino(BuildContext context, int posicion) {
    if (posicion == _posicionCrear) {
      context.push(RutasApp.crear);
      return;
    }
    final indiceRama = switch (posicion) {
      0 => 0,
      1 => 1,
      3 => 2,
      4 => 3,
      _ => 0,
    };
    navegacionRamas.goBranch(
      indiceRama,
      initialLocation: indiceRama == navegacionRamas.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navegacionRamas,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _posicionSeleccionada,
        onDestinationSelected: (posicion) =>
            _alSeleccionarDestino(context, posicion),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          const NavigationDestination(
            icon: Icon(Icons.auto_stories_outlined),
            selectedIcon: Icon(Icons.auto_stories),
            label: 'Momentos',
          ),
          NavigationDestination(
            icon: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: ColoresApp.acento,
                borderRadius: BorderRadius.circular(TemaApp.radioPequeno),
              ),
              child: const Icon(Icons.add, color: ColoresApp.sobrePrimario),
            ),
            label: '+',
          ),
          const NavigationDestination(
            icon: Icon(Icons.account_balance_outlined),
            selectedIcon: Icon(Icons.account_balance),
            label: 'Mi legado',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Yo',
          ),
        ],
      ),
    );
  }
}
