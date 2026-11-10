import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../nucleo/componentes/avisos_emergentes.dart';
import '../../../nucleo/componentes/boton_principal.dart';
import '../../../nucleo/enrutador/rutas_app.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../../../nucleo/tema/tema_app.dart';
import '../../elementos/dominio/elemento_borrador.dart';
import '../../elementos/dominio/tipo_elemento.dart';
import '../../musica/dominio/referencia_musica.dart';
import '../../recuerdos/aplicacion/controlador_recuerdos.dart';
import '../../recuerdos/aplicacion/proveedores_recuerdos.dart';
import '../../recuerdos/dominio/filtro_recuerdos.dart';
import '../../recuerdos/dominio/nuevo_recuerdo.dart';
import '../../recuerdos/dominio/recuerdo.dart';
import '../../recuerdos/dominio/validador_recuerdo.dart';
import '../../recuerdos/presentacion/componentes/vista_previa_borrador.dart';

/// Hoja inferior: guardar recuerdo en pocos taps tras el hub.
Future<Recuerdo?> mostrarPublicarRapido(
  BuildContext context,
  ElementoBorrador elemento,
) {
  return showModalBottomSheet<Recuerdo>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: ColoresApp.tarjeta,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(TemaApp.radioGrande)),
    ),
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      minChildSize: 0.38,
      maxChildSize: 0.92,
      builder: (_, scroll) => _ContenidoPublicarRapido(
        elemento: elemento,
        controladorScroll: scroll,
      ),
    ),
  );
}

class PantallaPublicarRapido extends ConsumerStatefulWidget {
  const PantallaPublicarRapido({super.key, required this.elemento});

  final ElementoBorrador elemento;

  @override
  ConsumerState<PantallaPublicarRapido> createState() =>
      _EstadoPantallaPublicarRapido();
}

class _EstadoPantallaPublicarRapido extends ConsumerState<PantallaPublicarRapido> {
  final _titulo = TextEditingController();

  @override
  void dispose() {
    _titulo.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    FocusScope.of(context).unfocus();
    final recuerdo = await ref.read(proveedorControladorRecuerdos.notifier).guardar(
          NuevoRecuerdo(
            elemento: widget.elemento,
            fechaRecuerdo:
                FiltroRecuerdos.soloDia(ref.read(proveedorReloj)()),
            titulo: _titulo.text,
          ),
        );
    if (recuerdo == null || !mounted) return;
    ref.read(proveedorBorradorRecuerdoPendiente.notifier).limpiar();
    context.pop(recuerdo);
  }

  void _masDetalles() {
    ref
        .read(proveedorBorradorRecuerdoPendiente.notifier)
        .establecer(widget.elemento);
    context.pop();
    context.push(RutasApp.guardarRecuerdo, extra: widget.elemento);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(proveedorControladorRecuerdos, (anterior, siguiente) {
      final error = siguiente.error;
      if (error != null && error != anterior?.error) {
        mostrarAvisoError(context, error);
        ref.read(proveedorControladorRecuerdos.notifier).limpiarError();
      }
    });
    final ocupado = ref.watch(
      proveedorControladorRecuerdos.select((e) => e.ocupado),
    );
    return Scaffold(
      backgroundColor: ColoresApp.tarjeta,
      appBar: AppBar(
        title: const Text('Guardar recuerdo'),
        leading: CloseButton(onPressed: ocupado ? null : () => context.pop()),
      ),
      body: _CuerpoPublicarRapido(
        elemento: widget.elemento,
        titulo: _titulo,
        ocupado: ocupado,
        alGuardar: _guardar,
        alMasDetalles: _masDetalles,
      ),
    );
  }
}

class _ContenidoPublicarRapido extends ConsumerStatefulWidget {
  const _ContenidoPublicarRapido({
    required this.elemento,
    required this.controladorScroll,
  });

  final ElementoBorrador elemento;
  final ScrollController controladorScroll;

  @override
  ConsumerState<_ContenidoPublicarRapido> createState() =>
      _EstadoContenidoPublicarRapido();
}

class _EstadoContenidoPublicarRapido
    extends ConsumerState<_ContenidoPublicarRapido> {
  final _titulo = TextEditingController();

  @override
  void dispose() {
    _titulo.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    FocusScope.of(context).unfocus();
    final recuerdo =
        await ref.read(proveedorControladorRecuerdos.notifier).guardar(
              NuevoRecuerdo(
                elemento: widget.elemento,
                fechaRecuerdo:
                    FiltroRecuerdos.soloDia(ref.read(proveedorReloj)()),
                titulo: _titulo.text,
              ),
            );
    if (recuerdo == null || !mounted) return;
    ref.read(proveedorBorradorRecuerdoPendiente.notifier).limpiar();
    mostrarAvisoInformativo(context, 'Guardado en tus recuerdos.');
    Navigator.of(context).pop(recuerdo);
  }

  void _masDetalles() {
    ref
        .read(proveedorBorradorRecuerdoPendiente.notifier)
        .establecer(widget.elemento);
    Navigator.of(context).pop();
    context.push(RutasApp.guardarRecuerdo, extra: widget.elemento);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(proveedorControladorRecuerdos, (anterior, siguiente) {
      final error = siguiente.error;
      if (error != null && error != anterior?.error) {
        mostrarAvisoError(context, error);
        ref.read(proveedorControladorRecuerdos.notifier).limpiarError();
      }
    });
    final ocupado = ref.watch(
      proveedorControladorRecuerdos.select((e) => e.ocupado),
    );
    return ListView(
      controller: widget.controladorScroll,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: ColoresApp.atenuado.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _CuerpoPublicarRapido(
          elemento: widget.elemento,
          titulo: _titulo,
          ocupado: ocupado,
          alGuardar: _guardar,
          alMasDetalles: _masDetalles,
        ),
      ],
    );
  }
}

class _CuerpoPublicarRapido extends StatelessWidget {
  const _CuerpoPublicarRapido({
    required this.elemento,
    required this.titulo,
    required this.ocupado,
    required this.alGuardar,
    required this.alMasDetalles,
  });

  final ElementoBorrador elemento;
  final TextEditingController titulo;
  final bool ocupado;
  final VoidCallback alGuardar;
  final VoidCallback alMasDetalles;

  @override
  Widget build(BuildContext context) {
    final musica = elemento.referenciaMusica;
    if (elemento.tipo == TipoElemento.musica && musica != null) {
      titulo.text = musica.etiquetaCorta;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 160,
          child: VistaPreviaBorrador(elemento: elemento),
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('campo-titulo-rapido'),
          controller: titulo,
          enabled: !ocupado,
          maxLength: ValidadorRecuerdo.caracteresMaxTitulo,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Título (opcional)',
            hintText: 'Ej.: Un momento especial',
          ),
        ),
        const SizedBox(height: 16),
        BotonPrincipal(
          etiqueta: 'Guardar',
          cargando: ocupado,
          alPresionar: alGuardar,
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: ocupado ? null : alMasDetalles,
          child: const Text('Más detalles (fecha, música…)'),
        ),
      ],
    );
  }
}
