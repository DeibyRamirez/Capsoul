import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';

import '../../../nucleo/componentes/app_bar_capsoul.dart';
import '../../../nucleo/componentes/avisos_emergentes.dart';
import '../../../nucleo/componentes/boton_principal.dart';
import '../../../nucleo/componentes/fondo_capsoul.dart';
import '../../../nucleo/componentes/pantalla_capsoul.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../../../nucleo/tema/tema_app.dart';
import '../dominio/elemento_borrador.dart';
import '../dominio/limites_medios.dart';
import '../dominio/nota_serializada.dart';
import '../dominio/tipo_elemento.dart';
import '../dominio/validador_medios.dart';

/// Nota de texto (hasta 5000 caracteres). Devuelve un [ElementoBorrador]
/// o, en edición, el texto serializado con `Navigator.pop`.
class PantallaEscribirNota extends StatefulWidget {
  const PantallaEscribirNota({
    super.key,
    this.contenidoInicial,
    this.modoEdicion = false,
  });

  final String? contenidoInicial;
  final bool modoEdicion;

  @override
  State<PantallaEscribirNota> createState() => _EstadoPantallaEscribirNota();
}

class _EstadoPantallaEscribirNota extends State<PantallaEscribirNota> {
  late final TextEditingController _texto;
  late EstiloNota _estilo;
  bool _vistaPrevia = false;

  @override
  void initState() {
    super.initState();
    final nota = NotaSerializada.parse(widget.contenidoInicial);
    _estilo = nota.estilo;
    _texto = TextEditingController(text: nota.cuerpo);
  }

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  void _aplicarFormato(String prefijo, String sufijo) {
    final sel = _texto.selection;
    final texto = _texto.text;
    if (!sel.isValid) return;
    final inicio = sel.start;
    final fin = sel.end;
    if (inicio < 0 || fin < 0) return;
    final seleccion = texto.substring(inicio, fin);
    final nuevo =
        '${texto.substring(0, inicio)}$prefijo$seleccion$sufijo${texto.substring(fin)}';
    _texto.value = TextEditingValue(
      text: nuevo,
      selection: TextSelection.collapsed(
        offset: inicio + prefijo.length + seleccion.length + sufijo.length,
      ),
    );
  }

  void _guardar() {
    final cuerpo = _texto.text.trim();
    final fallo = ValidadorMedios.validarNota(cuerpo);
    if (fallo != null) {
      mostrarAvisoError(context, fallo);
      return;
    }
    final serializado =
        NotaSerializada(estilo: _estilo, cuerpo: cuerpo).serializar();
    if (widget.modoEdicion) {
      context.pop(serializado);
      return;
    }
    context.pop(
      ElementoBorrador(
        idLocal: ElementoBorrador.nuevoIdLocal(),
        tipo: TipoElemento.texto,
        texto: serializado,
        bytes: serializado.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fam = _estilo.esPlayfair() ? TemaApp.fuenteTitulos : TemaApp.fuenteUi;
    return PantallaCapsoul(
      tipoFondo: FondoCapsoulTipo.plano,
      appBar: AppBarCapsoul(
        titulo: Text(widget.modoEdicion ? 'Editar nota' : 'Nota'),
        acciones: [
          IconButton(
            tooltip: _vistaPrevia ? 'Editar' : 'Vista previa',
            onPressed: () => setState(() => _vistaPrevia = !_vistaPrevia),
            icon: Icon(_vistaPrevia ? Icons.edit_outlined : Icons.visibility_outlined),
          ),
        ],
      ),
      cuerpo: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              children: [
                for (final entrada in _paletaFondos)
                  ChoiceChip(
                    label: Text(entrada.etiqueta),
                    selected: _estilo.fondo == entrada.clave,
                    onSelected: (_) =>
                        setState(() => _estilo = EstiloNota(fondo: entrada.clave)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'poppins', label: Text('Poppins')),
                ButtonSegment(value: 'playfair', label: Text('Playfair')),
              ],
              selected: {_estilo.fuente},
              onSelectionChanged: (sel) =>
                  setState(() => _estilo = EstiloNota(fuente: sel.first)),
            ),
            const SizedBox(height: 8),
            if (!_vistaPrevia)
              Row(
                children: [
                  IconButton(
                    tooltip: 'Negrilla',
                    onPressed: () => _aplicarFormato('**', '**'),
                    icon: const Icon(Icons.format_bold),
                  ),
                  IconButton(
                    tooltip: 'Cursiva',
                    onPressed: () => _aplicarFormato('_', '_'),
                    icon: const Icon(Icons.format_italic),
                  ),
                  IconButton(
                    tooltip: 'Subrayado',
                    onPressed: () => _aplicarFormato('<u>', '</u>'),
                    icon: const Icon(Icons.format_underlined),
                  ),
                ],
              ),
            Expanded(
              child: _vistaPrevia
                  ? Card(
                      color: _estilo.colorFondo(),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: MarkdownBody(
                          data: _texto.text,
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(
                              fontSize: 16,
                              height: 1.5,
                              fontFamily: fam,
                              color: ColoresApp.textoPrincipal,
                            ),
                          ),
                        ),
                      ),
                    )
                  : TextField(
                      key: const Key('campo-nota'),
                      controller: _texto,
                      autofocus: !widget.modoEdicion,
                      expands: true,
                      maxLines: null,
                      minLines: null,
                      style: TextStyle(fontFamily: fam),
                      textAlignVertical: TextAlignVertical.top,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      inputFormatters: const [LimitadorCaracteres()],
                      decoration: const InputDecoration(
                        hintText:
                            'Escribe una nota o una carta para el futuro…',
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _texto,
              builder: (context, valor, _) => Text(
                '${contarCaracteres(valor.text)} / '
                '${LimitesMedios.caracteresMaxNota}',
                textAlign: TextAlign.end,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: ColoresApp.atenuado),
              ),
            ),
            const SizedBox(height: 12),
            BotonPrincipal(
              etiqueta: widget.modoEdicion ? 'Guardar cambios' : 'Guardar nota',
              alPresionar: _guardar,
            ),
          ],
        ),
      ),
    );
  }
}

const _paletaFondos = [
  (clave: 'pastelAzul', etiqueta: 'Azul'),
  (clave: 'pastelVerde', etiqueta: 'Verde'),
  (clave: 'pastelRosa', etiqueta: 'Rosa'),
];

/// Corta el texto en [LimitesMedios.caracteresMaxNota] caracteres contados
/// como Postgres (`char_length`).
class LimitadorCaracteres extends TextInputFormatter {
  const LimitadorCaracteres();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue anterior,
    TextEditingValue nuevo,
  ) {
    if (contarCaracteres(nuevo.text) <= LimitesMedios.caracteresMaxNota) {
      return nuevo;
    }
    final recortado = String.fromCharCodes(
      nuevo.text.runes.take(LimitesMedios.caracteresMaxNota),
    );
    return TextEditingValue(
      text: recortado,
      selection: TextSelection.collapsed(offset: recortado.length),
    );
  }
}
