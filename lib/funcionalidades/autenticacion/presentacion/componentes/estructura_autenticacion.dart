import 'package:flutter/material.dart';

import '../../../../nucleo/componentes/ilustracion_marca.dart';
import '../../../../nucleo/tema/colores_app.dart';
import '../../../../nucleo/tema/espaciado_app.dart';

/// Autenticación sobre la acuarela clara: el borde inferior del dibujo se
/// funde con el fondo [ColoresApp.superficie] y el formulario sigue debajo.
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
    final alto = MediaQuery.sizeOf(context).height;
    final altoHero = alto < 700 ? 148.0 : 240.0;
    return Scaffold(
      backgroundColor: ColoresApp.superficie,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            SizedBox(
              height: altoHero,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const ColoredBox(color: ColoresApp.superficie),
                  const IlustracionMarca(
                    ruta: IlustracionesMarca.heroCalma,
                    alineacion: Alignment.topCenter,
                    fundirAbajo: true,
                  ),
                  if (mostrarAtras)
                    const SafeArea(
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: BackButton(color: ColoresApp.textoPrincipal),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  EspaciadoApp.pantalla,
                  EspaciadoApp.xs,
                  EspaciadoApp.pantalla,
                  EspaciadoApp.lg,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: contenido,
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
