import 'package:flutter/material.dart';

import '../../../../nucleo/tema/colores_app.dart';
import '../../../../nucleo/tema/tema_app.dart';
import '../../../elementos/dominio/nota_serializada.dart';
import '../../../elementos/presentacion/componentes/vista_nota_rica.dart';

/// Preview de nota en espacios pequeños (rejilla, cápsula, borrador).
class VistaNotaCompacta extends StatelessWidget {
  const VistaNotaCompacta({
    super.key,
    required this.contenidoTexto,
    this.contenidoRico,
    this.tamanoFuente = 12,
    this.rellenar = true,
  });

  final String? contenidoTexto;
  final Object? contenidoRico;
  final double tamanoFuente;

  /// Si es true, ocupa todo el espacio del padre (miniatura cuadrada).
  final bool rellenar;

  @override
  Widget build(BuildContext context) {
    final nota = NotaSerializada.desdeColumnas(
      contenidoTexto: contenidoTexto,
      contenidoRico: contenidoRico,
    );
    final cuerpo = nota.cuerpo.isEmpty ? ' ' : nota.cuerpo;

    if (rellenar) {
      return ColoredBox(
        color: nota.estilo.colorFondo(),
        child: SizedBox.expand(
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Align(
              alignment: Alignment.topLeft,
              child: Text(
                NotaSerializada.markdownAPlano(cuerpo),
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9,
                  height: 1.25,
                  fontFamily: nota.estilo.esPlayfair()
                      ? TemaApp.fuenteTitulos
                      : TemaApp.fuenteUi,
                  color: ColoresApp.textoPrincipal,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return ColoredBox(
      color: nota.estilo.colorFondo(),
      child: SizedBox.expand(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: VistaNotaRica(
              nota: nota,
              tamanoFuente: tamanoFuente,
              alturaLinea: 1.3,
            ),
          ),
        ),
      ),
    );
  }
}
