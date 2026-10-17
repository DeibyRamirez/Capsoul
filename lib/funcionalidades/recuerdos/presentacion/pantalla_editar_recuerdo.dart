import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../nucleo/componentes/avisos_emergentes.dart';
import '../../../nucleo/errores/fallo_app.dart';
import '../../../nucleo/componentes/boton_principal.dart';
import '../../../nucleo/componentes/cabecera_detalle_capsoul.dart';
import '../../../nucleo/componentes/menu_acciones_entidad.dart';
import '../../../nucleo/formato/fechas.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../../autenticacion/aplicacion/proveedores_autenticacion.dart';
import '../../elementos/dominio/tipo_elemento.dart';
import '../../elementos/presentacion/pantalla_escribir_nota.dart';
import '../aplicacion/controlador_recuerdos.dart';
import '../aplicacion/proveedores_recuerdos.dart';
import '../dominio/filtro_recuerdos.dart';
import '../dominio/recuerdo.dart';
import '../dominio/validador_recuerdo.dart';
import 'acciones_recuerdo.dart';
import 'componentes/vista_recuerdo.dart';

/// Edición y gestión de un recuerdo (metadatos y, en notas, el cuerpo).
class PantallaEditarRecuerdo extends ConsumerWidget {
  const PantallaEditarRecuerdo({super.key, required this.idRecuerdo});

  final String idRecuerdo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recuerdo = ref.watch(proveedorRecuerdo(idRecuerdo));
    return Scaffold(
      backgroundColor: ColoresApp.superficie,
      body: recuerdo.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _Mensaje(mensajeParaUsuario(error)),
        data: (datos) => datos == null
            ? const _Mensaje('Este recuerdo no existe o no puedes verlo.')
            : _ContenidoEditar(recuerdo: datos),
      ),
    );
  }
}

class _ContenidoEditar extends ConsumerStatefulWidget {
  const _ContenidoEditar({required this.recuerdo});

  final Recuerdo recuerdo;

  @override
  ConsumerState<_ContenidoEditar> createState() => _EstadoContenidoEditar();
}

class _EstadoContenidoEditar extends ConsumerState<_ContenidoEditar> {
  final _titulo = TextEditingController();
  late DateTime _fecha;
  var _cargado = false;
  var _guardando = false;

  @override
  void initState() {
    super.initState();
    _fecha = widget.recuerdo.fechaRecuerdo;
    _titulo.text = widget.recuerdo.titulo ?? '';
  }

  @override
  void didUpdateWidget(covariant _ContenidoEditar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.recuerdo.id != widget.recuerdo.id) {
      _fecha = widget.recuerdo.fechaRecuerdo;
      _titulo.text = widget.recuerdo.titulo ?? '';
    }
  }

  @override
  void dispose() {
    _titulo.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final hoy = FiltroRecuerdos.soloDia(DateTime.now());
    final elegida = await showDatePicker(
      context: context,
      helpText: 'Fecha del recuerdo',
      cancelText: 'Cancelar',
      confirmText: 'Elegir',
      firstDate: ValidadorRecuerdo.primeraFecha,
      lastDate: hoy,
      initialDate: _fecha.isAfter(hoy) ? hoy : _fecha,
    );
    if (elegida != null && mounted) setState(() => _fecha = elegida);
  }

  Future<void> _editarNota() async {
    final recuerdo = widget.recuerdo;
    final serializado = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => PantallaEscribirNota(
          contenidoInicial: recuerdo.contenidoTexto,
          modoEdicion: true,
        ),
      ),
    );
    if (serializado == null || !mounted) return;
    try {
      await ref
          .read(proveedorRepositorioRecuerdos)
          .actualizarContenidoTexto(recuerdo.id, serializado);
      ref.invalidate(proveedorRecuerdo(recuerdo.id));
      if (mounted) mostrarAvisoInformativo(context, 'Nota actualizada.');
    } catch (error) {
      if (mounted) mostrarAvisoError(context, error);
    }
  }

  Future<void> _guardar() async {
    if (_guardando) return;
    setState(() => _guardando = true);
    final recuerdo = widget.recuerdo;
    final titulo = _titulo.text.trim();
    try {
      await ref.read(proveedorRepositorioRecuerdos).actualizarMetadatos(
            recuerdo.id,
            titulo: titulo.isEmpty ? null : titulo,
            fechaRecuerdo: _fecha,
          );
      ref.invalidate(proveedorRecuerdo(recuerdo.id));
      if (mounted) {
        mostrarAvisoInformativo(context, 'Recuerdo actualizado.');
        context.pop();
      }
    } catch (error) {
      if (mounted) mostrarAvisoError(context, error);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _borrar() async {
    await borrarRecuerdoConConfirmacion(
      context,
      ref,
      widget.recuerdo,
      alExito: () => context.pop(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recuerdo = ref.watch(proveedorRecuerdo(widget.recuerdo.id)).value ??
        widget.recuerdo;
    if (!_cargado) {
      _cargado = true;
      _fecha = recuerdo.fechaRecuerdo;
      if (_titulo.text.isEmpty && (recuerdo.titulo ?? '').isNotEmpty) {
        _titulo.text = recuerdo.titulo!;
      }
    }
    final uid = ref.watch(
      proveedorEstadoAutenticacion.select((estado) => estado.value?.uid),
    );
    final ocupado = ref.watch(
      proveedorControladorRecuerdos.select((estado) => estado.ocupado),
    );
    final esPropietario = recuerdo.propietarioId == uid;
    final estilos = Theme.of(context).textTheme;

    return Column(
      children: [
        CabeceraDetalleCapsoul(
          titulo: 'Editar recuerdo',
          subtitulo: recuerdo.nombre,
          trailing: esPropietario
              ? MenuAccionesEntidad(
                  key: const Key('menu-acciones-recuerdo'),
                  compacto: true,
                  puedeEditar: recuerdo.tipo == TipoElemento.texto,
                  puedeEliminar: true,
                  pedirConfirmacionEliminar: false,
                  etiquetaEliminar: 'Borrar recuerdo',
                  tituloConfirmacion: '¿Borrar este recuerdo?',
                  mensajeConfirmacion:
                      'Se quitará también de los momentos y de las cápsulas '
                      'en borrador donde esté. No se puede deshacer.',
                  cargando: ocupado || _guardando,
                  alEditar: _editarNota,
                  alEliminar: _borrar,
                )
              : null,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              TextField(
                key: const Key('campo-titulo-editar-recuerdo'),
                controller: _titulo,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  hintText: 'Opcional',
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _guardando ? null : _elegirFecha,
                icon: const Icon(Icons.calendar_today_outlined, size: 18),
                label: Text(formatearFechaCorta(_fecha)),
              ),
              const SizedBox(height: 20),
              Text(
                'Vista previa',
                style: estilos.titleSmall?.copyWith(color: ColoresApp.atenuado),
              ),
              const SizedBox(height: 8),
              IgnorePointer(
                child: Opacity(
                  opacity: 0.95,
                  child: VistaRecuerdo(recuerdo: recuerdo),
                ),
              ),
              if (recuerdo.tipo == TipoElemento.texto) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _editarNota,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar texto de la nota'),
                ),
              ],
              const SizedBox(height: 24),
              BotonPrincipal(
                etiqueta: 'Guardar cambios',
                cargando: _guardando,
                alPresionar: _guardar,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Mensaje extends StatelessWidget {
  const _Mensaje(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(texto, textAlign: TextAlign.center),
        ),
      );
}
