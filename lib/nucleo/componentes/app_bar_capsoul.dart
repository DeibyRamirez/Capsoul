import 'package:flutter/material.dart';

import '../tema/colores_app.dart';
import '../tema/tema_app.dart';

/// Estilo de la barra superior según el fondo detrás.
enum EstiloBarraSuperior {
  /// Degradado o superficie clara: título e iconos azul marino.
  claro,

  /// Fondo medianoche: título e iconos blancos.
  oscuro,
}

/// AppBar de Capsoul con colores coherentes al fondo.
class AppBarCapsoul extends StatelessWidget implements PreferredSizeWidget {
  const AppBarCapsoul({
    super.key,
    required this.titulo,
    this.estilo = EstiloBarraSuperior.claro,
    this.acciones,
    this.alAtras,
    this.automaticallyImplyLeading = true,
  });

  final Widget titulo;
  final EstiloBarraSuperior estilo;
  final List<Widget>? acciones;
  final VoidCallback? alAtras;
  final bool automaticallyImplyLeading;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final oscuro = estilo == EstiloBarraSuperior.oscuro;
    final colorTexto =
        oscuro ? ColoresApp.sobrePrimario : ColoresApp.textoPrincipal;
    final colorIcono = oscuro ? ColoresApp.sobrePrimario : ColoresApp.primario;

    return AppBar(
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor: oscuro ? ColoresApp.medianoche : Colors.transparent,
      surfaceTintColor: Colors.transparent,
      foregroundColor: colorTexto,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: colorIcono),
      actionsIconTheme: IconThemeData(color: colorIcono),
      leading: alAtras != null
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: alAtras,
            )
          : null,
      title: DefaultTextStyle.merge(
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorTexto,
              fontWeight: FontWeight.w600,
              fontFamily: TemaApp.fuenteUi,
            ),
        child: titulo,
      ),
      actions: acciones,
    );
  }
}
