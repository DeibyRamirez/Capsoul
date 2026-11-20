import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../../nucleo/tema/colores_app.dart';
import '../../../../nucleo/tema/tema_app.dart';
import '../../dominio/nota_serializada.dart';

/// Renderiza una nota enriquecida sin montar otro editor.
///
/// Las notas nuevas se pintan desde el Delta con [TextSpan]. Las notas
/// antiguas siguen usando Markdown para conservar su formato.
class VistaNotaRica extends StatelessWidget {
  const VistaNotaRica({
    super.key,
    required this.nota,
    this.tamanoFuente = 16,
    this.alturaLinea = 1.5,
    this.seleccionable = false,
  });

  final NotaSerializada nota;
  final double tamanoFuente;
  final double alturaLinea;
  final bool seleccionable;

  @override
  Widget build(BuildContext context) {
    final familia = nota.estilo.esPlayfair()
        ? TemaApp.fuenteTitulos
        : TemaApp.fuenteUi;
    final estiloBase = TextStyle(
      fontSize: tamanoFuente,
      height: alturaLinea,
      fontFamily: familia,
      color: ColoresApp.textoPrincipal,
    );

    if (!nota.esRica) {
      final markdown = nota.cuerpo.isEmpty ? ' ' : nota.cuerpo;
      return MarkdownBody(
        data: markdown,
        selectable: seleccionable,
        styleSheet: MarkdownStyleSheet(
          p: estiloBase,
          strong: estiloBase.copyWith(fontWeight: FontWeight.w700),
          em: estiloBase.copyWith(fontStyle: FontStyle.italic),
        ),
      );
    }

    final operaciones = _sinSaltoTecnico(nota.delta!);
    final span = TextSpan(
      style: estiloBase,
      children: [
        for (final operacion in operaciones)
          if (operacion['insert'] is String)
            TextSpan(
              text: operacion['insert'] as String,
              style: _estiloAtributos(operacion['attributes']),
            ),
      ],
    );
    if (seleccionable) {
      return SelectableText.rich(span);
    }
    return Text.rich(span);
  }

  TextStyle? _estiloAtributos(Object? raw) {
    if (raw is! Map) return null;
    final negrita = raw['bold'] == true;
    final cursiva = raw['italic'] == true;
    final subrayado = raw['underline'] == true;
    if (!negrita && !cursiva && !subrayado) return null;
    return TextStyle(
      fontWeight: negrita ? FontWeight.w700 : null,
      fontStyle: cursiva ? FontStyle.italic : null,
      decoration: subrayado ? TextDecoration.underline : null,
    );
  }

  /// Quita el salto de línea técnico que Quill añade al final de la nota.
  List<Map<String, dynamic>> _sinSaltoTecnico(
    List<Map<String, dynamic>> delta,
  ) {
    if (delta.isEmpty) return delta;
    final copia = [
      for (final operacion in delta) Map<String, dynamic>.from(operacion),
    ];
    final ultimo = copia.last['insert'];
    if (ultimo is String && ultimo.endsWith('\n')) {
      final recortado = ultimo.substring(0, ultimo.length - 1);
      if (recortado.isEmpty) {
        copia.removeLast();
      } else {
        copia.last['insert'] = recortado;
      }
    }
    return copia;
  }
}
