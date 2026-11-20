// La configuración de portapapeles de flutter_quill sigue marcada como
// experimental, pero es la vía oficial para desactivar el pegado enriquecido.
// ignore_for_file: experimental_member_use

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:go_router/go_router.dart';

import '../../../nucleo/componentes/avisos_emergentes.dart';
import '../../../nucleo/componentes/pantalla_capsoul.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../../../nucleo/tema/tema_app.dart';
import '../dominio/elemento_borrador.dart';
import '../dominio/limites_medios.dart';
import '../dominio/nota_delta.dart';
import '../dominio/nota_serializada.dart';
import '../dominio/tipo_elemento.dart';
import '../dominio/validador_medios.dart';

/// Nota de texto (hasta 5000 caracteres) con edición enriquecida.
///
/// Devuelve un [ElementoBorrador] al crear o el texto serializado con
/// `Navigator.pop` al editar.
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
  late final quill.QuillController _controlador;
  late final FocusNode _foco;
  late final ScrollController _scroll;
  late EstiloNota _estilo;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final nota = NotaSerializada.parse(widget.contenidoInicial);
    _estilo = nota.estilo;
    final delta =
        nota.delta ??
        (nota.cuerpo.isEmpty
            ? deltaDesdeTextoPlano('')
            : deltaDesdeMarkdownLegacy(nota.cuerpo));
    _controlador = quill.QuillController(
      document: quill.Document.fromJson(delta),
      selection: const TextSelection.collapsed(offset: 0),
      config: quill.QuillControllerConfig(
        clipboardConfig: quill.QuillClipboardConfig(
          enableExternalRichPaste: false,
          onPlainTextPaste: _recortarPegado,
        ),
      ),
      onReplaceText: _permitirReemplazo,
    );
    _foco = FocusNode();
    _scroll = ScrollController();
  }

  @override
  void dispose() {
    _controlador.dispose();
    _foco.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String get _textoPlano =>
      _controlador.document.toPlainText().replaceFirst(RegExp(r'\n$'), '');

  bool _permitirReemplazo(int index, int len, Object? data) {
    if (data is! String) return false;
    if (data.isEmpty) return true;
    final actual = _textoPlano;
    final inicio = index.clamp(0, actual.length).toInt();
    final fin = (index + len).clamp(inicio, actual.length).toInt();
    final nuevo = actual.replaceRange(inicio, fin, data);
    return contarCaracteres(nuevo) <= LimitesMedios.caracteresMaxNota;
  }

  Future<String?> _recortarPegado(String texto) async {
    final actual = _textoPlano;
    final seleccion = _controlador.selection;
    var seleccionados = 0;
    if (seleccion.isValid && !seleccion.isCollapsed) {
      final inicio = seleccion.start.clamp(0, actual.length).toInt();
      final fin = seleccion.end.clamp(inicio, actual.length).toInt();
      seleccionados = contarCaracteres(actual.substring(inicio, fin));
    }
    final disponibles =
        LimitesMedios.caracteresMaxNota -
        contarCaracteres(actual) +
        seleccionados;
    if (disponibles <= 0) return '';
    return String.fromCharCodes(texto.runes.take(disponibles));
  }

  void _guardar() {
    if (_guardando) return;
    final cuerpo = _textoPlano.trim();
    final fallo = ValidadorMedios.validarNota(cuerpo);
    if (fallo != null) {
      mostrarAvisoError(context, fallo);
      return;
    }
    _guardando = true;
    final delta = sanitizarDelta(_controlador.document.toDelta().toJson());
    final serializado = NotaSerializada(
      estilo: _estilo,
      cuerpo: cuerpo,
      delta: delta,
    ).serializar();
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

  Future<void> _abrirEstilo() async {
    _foco.unfocus();
    final elegido = await showModalBottomSheet<EstiloNota>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _HojaEstiloNota(estiloInicial: _estilo),
    );
    if (elegido != null && mounted) {
      setState(() => _estilo = elegido);
    }
  }

  quill.QuillEditorConfig _configEditor(BuildContext context) {
    final fam = _estilo.esPlayfair() ? TemaApp.fuenteTitulos : TemaApp.fuenteUi;
    final base = quill.DefaultStyles.getInstance(context);
    final parrafo = quill.DefaultTextBlockStyle(
      TextStyle(
        fontFamily: fam,
        fontSize: 16,
        height: 1.5,
        color: ColoresApp.textoPrincipal,
      ),
      const quill.HorizontalSpacing(0, 0),
      const quill.VerticalSpacing(0, 0),
      const quill.VerticalSpacing(0, 0),
      null,
    );
    final placeholder = quill.DefaultTextBlockStyle(
      TextStyle(
        fontFamily: fam,
        fontSize: 16,
        height: 1.5,
        color: ColoresApp.atenuado,
      ),
      const quill.HorizontalSpacing(0, 0),
      const quill.VerticalSpacing(0, 0),
      const quill.VerticalSpacing(0, 0),
      null,
    );
    return quill.QuillEditorConfig(
      expands: true,
      padding: EdgeInsets.zero,
      autoFocus: !widget.modoEdicion,
      placeholder: 'Escribe una nota o una carta para el futuro…',
      textCapitalization: TextCapitalization.sentences,
      customStyles: base.merge(
        quill.DefaultStyles(
          paragraph: parrafo,
          placeHolder: placeholder,
          bold: const TextStyle(fontWeight: FontWeight.w700),
          italic: const TextStyle(fontStyle: FontStyle.italic),
          underline: const TextStyle(decoration: TextDecoration.underline),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tecladoAbierto = MediaQuery.viewInsetsOf(context).bottom > 0;
    return PantallaCapsoul(
      usarAreaSegura: false,
      cuerpo: Column(
        children: [
          _CabeceraNota(
            titulo: widget.modoEdicion ? 'Editar nota' : 'Nueva nota',
            controlador: _controlador,
            alGuardar: _guardar,
            alAbrirEstilo: _abrirEstilo,
          ),
          Expanded(
            child: SafeArea(
              top: false,
              bottom: !tecladoAbierto,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  tecladoAbierto ? 8 : 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: _estilo.colorFondo(),
                          borderRadius: BorderRadius.circular(
                            TemaApp.radioGrande,
                          ),
                          border: Border.all(color: ColoresApp.bordeTarjeta),
                          boxShadow: TemaApp.sombraTarjeta,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: quill.QuillEditor.basic(
                            key: const Key('campo-nota'),
                            controller: _controlador,
                            focusNode: _foco,
                            scrollController: _scroll,
                            config: _configEditor(context),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListenableBuilder(
                      listenable: _controlador,
                      builder: (context, _) => Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${contarCaracteres(_textoPlano)} / '
                          '${LimitesMedios.caracteresMaxNota}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: ColoresApp.atenuado),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _BarraFormatoNota(controlador: _controlador),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Cabecera compacta con guardar siempre a la vista.
class _CabeceraNota extends StatelessWidget {
  const _CabeceraNota({
    required this.titulo,
    required this.controlador,
    required this.alGuardar,
    required this.alAbrirEstilo,
  });

  final String titulo;
  final quill.QuillController controlador;
  final VoidCallback alGuardar;
  final VoidCallback alAbrirEstilo;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
        child: Row(
          children: [
            const BackButton(color: ColoresApp.textoPrincipal),
            Expanded(
              child: Text(
                titulo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: estilos.titleLarge?.copyWith(
                  fontFamily: TemaApp.fuenteTitulos,
                  fontWeight: FontWeight.w600,
                  color: ColoresApp.textoPrincipal,
                ),
              ),
            ),
            IconButton(
              key: const Key('estilo-nota'),
              tooltip: 'Estilo de la nota',
              onPressed: alAbrirEstilo,
              icon: const Icon(Icons.palette_outlined),
            ),
            ListenableBuilder(
              listenable: controlador,
              builder: (context, _) {
                final tieneTexto = controlador.document
                    .toPlainText()
                    .trim()
                    .isNotEmpty;
                return TextButton(
                  key: const Key('guardar-nota'),
                  onPressed: tieneTexto ? alGuardar : null,
                  child: const Text('Guardar'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Barra de formato del editor: sin símbolos visibles para el usuario.
class _BarraFormatoNota extends StatelessWidget {
  const _BarraFormatoNota({required this.controlador});

  final quill.QuillController controlador;

  void _alternar(quill.Attribute atributo) {
    final activo = controlador.getSelectionStyle().attributes.containsKey(
      atributo.key,
    );
    controlador.formatSelection(
      activo ? quill.Attribute.clone(atributo, null) : atributo,
    );
  }

  void _quitarFormato() {
    for (final atributo in [
      quill.Attribute.bold,
      quill.Attribute.italic,
      quill.Attribute.underline,
    ]) {
      controlador.formatSelection(quill.Attribute.clone(atributo, null));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColoresApp.tarjeta,
        borderRadius: BorderRadius.circular(TemaApp.radioGrande),
        border: Border.all(color: ColoresApp.bordeTarjeta),
        boxShadow: TemaApp.sombraTarjeta,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: ListenableBuilder(
        listenable: controlador,
        builder: (context, _) {
          final atributos = controlador.getSelectionStyle().attributes;
          bool activo(quill.Attribute atributo) =>
              atributos.containsKey(atributo.key);
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _BotonFormatoQuill(
                  clave: const Key('formato-negrita'),
                  icono: Icons.format_bold,
                  etiqueta: 'Negrita',
                  activo: activo(quill.Attribute.bold),
                  alPresionar: () => _alternar(quill.Attribute.bold),
                ),
                _BotonFormatoQuill(
                  clave: const Key('formato-cursiva'),
                  icono: Icons.format_italic,
                  etiqueta: 'Cursiva',
                  activo: activo(quill.Attribute.italic),
                  alPresionar: () => _alternar(quill.Attribute.italic),
                ),
                _BotonFormatoQuill(
                  clave: const Key('formato-subrayado'),
                  icono: Icons.format_underlined,
                  etiqueta: 'Subrayado',
                  activo: activo(quill.Attribute.underline),
                  alPresionar: () => _alternar(quill.Attribute.underline),
                ),
                const _SeparadorFormato(),
                _BotonFormatoQuill(
                  clave: const Key('formato-normal'),
                  icono: Icons.format_clear,
                  etiqueta: 'Quitar formato',
                  activo: false,
                  alPresionar: _quitarFormato,
                ),
                const _SeparadorFormato(),
                _BotonFormatoQuill(
                  clave: const Key('formato-deshacer'),
                  icono: Icons.undo,
                  etiqueta: 'Deshacer',
                  activo: false,
                  habilitado: controlador.hasUndo,
                  alPresionar: controlador.undo,
                ),
                _BotonFormatoQuill(
                  clave: const Key('formato-rehacer'),
                  icono: Icons.redo,
                  etiqueta: 'Rehacer',
                  activo: false,
                  habilitado: controlador.hasRedo,
                  alPresionar: controlador.redo,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BotonFormatoQuill extends StatelessWidget {
  const _BotonFormatoQuill({
    required this.clave,
    required this.icono,
    required this.etiqueta,
    required this.activo,
    required this.alPresionar,
    this.habilitado = true,
  });

  final Key clave;
  final IconData icono;
  final String etiqueta;
  final bool activo;
  final bool habilitado;
  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: clave,
      tooltip: etiqueta,
      isSelected: activo,
      onPressed: habilitado ? alPresionar : null,
      icon: Icon(icono, size: 20),
      style: IconButton.styleFrom(
        minimumSize: const Size(44, 44),
        foregroundColor: activo
            ? ColoresApp.sobrePrimario
            : ColoresApp.primario,
        backgroundColor: activo ? ColoresApp.primario : Colors.transparent,
        disabledForegroundColor: ColoresApp.atenuado.withValues(alpha: 0.4),
        shape: const CircleBorder(),
      ),
    );
  }
}

class _SeparadorFormato extends StatelessWidget {
  const _SeparadorFormato();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: ColoresApp.bordeTarjeta,
    );
  }
}

class _HojaEstiloNota extends StatefulWidget {
  const _HojaEstiloNota({required this.estiloInicial});

  final EstiloNota estiloInicial;

  @override
  State<_HojaEstiloNota> createState() => _EstadoHojaEstiloNota();
}

class _EstadoHojaEstiloNota extends State<_HojaEstiloNota> {
  late String _fondo;
  late String _fuente;

  @override
  void initState() {
    super.initState();
    _fondo = widget.estiloInicial.fondo;
    _fuente = widget.estiloInicial.fuente;
  }

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estilo de la nota',
              style: estilos.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Text(
              'Color',
              style: estilos.labelLarge?.copyWith(
                color: ColoresApp.atenuado,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final entrada in _paletaFondos) ...[
                  _CirculoColor(
                    key: ValueKey('color-${entrada.clave}'),
                    entrada: entrada,
                    seleccionado: _fondo == entrada.clave,
                    alTocar: () => setState(() => _fondo = entrada.clave),
                  ),
                  const SizedBox(width: 14),
                ],
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Tipografía',
              style: estilos.labelLarge?.copyWith(
                color: ColoresApp.atenuado,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              showSelectedIcon: false,
              expandedInsets: EdgeInsets.zero,
              segments: const [
                ButtonSegment(value: 'poppins', label: Text('Poppins')),
                ButtonSegment(value: 'playfair', label: Text('Playfair')),
              ],
              selected: {_fuente},
              onSelectionChanged: (seleccion) =>
                  setState(() => _fuente = seleccion.first),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(
                  context,
                  EstiloNota(fondo: _fondo, fuente: _fuente),
                ),
                child: const Text('Aplicar estilo'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CirculoColor extends StatelessWidget {
  const _CirculoColor({
    super.key,
    required this.entrada,
    required this.seleccionado,
    required this.alTocar,
  });

  final ({String clave, String etiqueta}) entrada;
  final bool seleccionado;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final color = EstiloNota(fondo: entrada.clave).colorFondo();
    return Semantics(
      button: true,
      selected: seleccionado,
      label: 'Color ${entrada.etiqueta}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: alTocar,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 48,
              height: 48,
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: seleccionado
                        ? ColoresApp.primario
                        : ColoresApp.bordeTarjeta,
                    width: seleccionado ? 2 : 1,
                  ),
                ),
                child: seleccionado
                    ? const Icon(
                        Icons.check,
                        size: 20,
                        color: ColoresApp.primario,
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            entrada.etiqueta,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: seleccionado ? ColoresApp.primario : ColoresApp.atenuado,
              fontWeight: seleccionado ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

const _paletaFondos = [
  (clave: 'pastelAzul', etiqueta: 'Azul'),
  (clave: 'pastelVerde', etiqueta: 'Verde'),
  (clave: 'pastelRosa', etiqueta: 'Rosa'),
];
