import 'package:flutter/material.dart';

import 'fondo_capsoul.dart';

/// Scaffold estándar con fondo Capsoul y área segura opcional.
class PantallaCapsoul extends StatelessWidget {
  const PantallaCapsoul({
    super.key,
    required this.cuerpo,
    this.tipoFondo = FondoCapsoulTipo.suave,
    this.mostrarCieloAnimado = false,
    this.brilloCielo = 1,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.extendBodyBehindAppBar = false,
    this.usarAreaSegura = true,
    this.fondoScaffold = Colors.transparent,
  });

  final Widget cuerpo;
  final FondoCapsoulTipo tipoFondo;
  final bool mostrarCieloAnimado;
  final double brilloCielo;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final bool extendBodyBehindAppBar;
  final bool usarAreaSegura;
  final Color fondoScaffold;

  @override
  Widget build(BuildContext context) {
    final contenido = FondoCapsoul(
      tipo: tipoFondo,
      conCieloAnimado: mostrarCieloAnimado,
      brilloCielo: brilloCielo,
      child: usarAreaSegura ? SafeArea(child: cuerpo) : cuerpo,
    );

    return Scaffold(
      backgroundColor: fondoScaffold,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      body: contenido,
    );
  }
}
