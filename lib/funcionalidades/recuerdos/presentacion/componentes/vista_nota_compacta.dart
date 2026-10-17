import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../../nucleo/tema/colores_app.dart';
import '../../../../nucleo/tema/tema_app.dart';
import '../../../elementos/dominio/nota_serializada.dart';

/// Preview de nota en espacios pequeños (rejilla, cápsula, borrador).
class VistaNotaCompacta extends StatelessWidget {
  const VistaNotaCompacta({
    super.key,
    required this.contenidoTexto,
    this.tamanoFuente = 12,
    this.rellenar = true,
  });

  final String? contenidoTexto;
  final double tamanoFuente;

  /// Si es true, ocupa todo el espacio del padre (miniatura cuadrada).
  final bool rellenar;

  @override
  Widget build(BuildContext context) {
    final nota = NotaSerializada.parse(contenidoTexto);
    final fam =
        nota.estilo.esPlayfair() ? TemaApp.fuenteTitulos : TemaApp.fuenteUi;
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
                  fontFamily: fam,
                  color: ColoresApp.textoPrincipal,
                ),
              ),
            ),
          ),
        ),
      );
    }

    final markdown = MarkdownBody(
      data: cuerpo,
      shrinkWrap: true,
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(
          fontSize: tamanoFuente,
          height: 1.3,
          fontFamily: fam,
          color: ColoresApp.textoPrincipal,
        ),
        strong: TextStyle(
          fontSize: tamanoFuente,
          height: 1.3,
          fontFamily: fam,
          fontWeight: FontWeight.w700,
          color: ColoresApp.textoPrincipal,
        ),
        em: TextStyle(
          fontSize: tamanoFuente,
          height: 1.3,
          fontFamily: fam,
          fontStyle: FontStyle.italic,
          color: ColoresApp.textoPrincipal,
        ),
      ),
    );

    return ColoredBox(
      color: nota.estilo.colorFondo(),
      child: SizedBox.expand(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(child: markdown),
        ),
      ),
    );
  }
}
