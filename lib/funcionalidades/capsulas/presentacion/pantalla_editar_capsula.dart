import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../nucleo/componentes/app_bar_capsoul.dart';
import '../../../nucleo/componentes/avisos_emergentes.dart';
import '../../../nucleo/componentes/boton_principal.dart';
import '../../../nucleo/componentes/pantalla_capsoul.dart';
import '../../../nucleo/enrutador/rutas_app.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../../autenticacion/aplicacion/proveedores_autenticacion.dart';
import '../../elementos/dominio/tipo_elemento.dart';
import '../../recuerdos/dominio/recuerdo.dart';
import '../../recuerdos/presentacion/componentes/hoja_nuevo_recuerdo.dart';
import '../../recuerdos/presentacion/pantalla_elegir_recuerdos.dart';
import '../aplicacion/controlador_editar_capsula.dart';
import '../aplicacion/proveedores_capsulas.dart';
import '../dominio/estado_capsula.dart';
import '../dominio/validador_capsula.dart';
import 'componentes/botones_agregar_elemento.dart';
import 'componentes/elegir_fecha_hora_apertura.dart';
import 'componentes/interruptor_capsula_para_mi.dart';
import 'componentes/selector_destinatarios_amigos.dart';
import 'componentes/selector_imagen_capsula.dart';
import 'componentes/tarjeta_recuerdo_elegido.dart';

/// Edición de una cápsula en borrador o programada (metadatos, recuerdos y destinatarios).
class PantallaEditarCapsula extends ConsumerStatefulWidget {
  const PantallaEditarCapsula({super.key, required this.idCapsula});

  final String idCapsula;

  @override
  ConsumerState<PantallaEditarCapsula> createState() =>
      _EstadoPantallaEditarCapsula();
}

class _EstadoPantallaEditarCapsula extends ConsumerState<PantallaEditarCapsula> {
  final _titulo = TextEditingController();
  final _mensaje = TextEditingController();
  var _camposTextoCargados = false;

  @override
  void dispose() {
    _titulo.dispose();
    _mensaje.dispose();
    super.dispose();
  }

  ControladorEditarCapsula get _controlador =>
      ref.read(proveedorControladorEditarCapsula.notifier);

  Future<void> _elegirDeMisRecuerdos() async {
    final estado = ref.read(proveedorControladorEditarCapsula);
    final elegidos = await context.push<List<Recuerdo>>(
      RutasApp.elegirRecuerdos,
      extra: ParametrosElegirRecuerdos(
        titulo: 'Recuerdos para la cápsula',
        yaElegidos: estado.idsElegidos,
        maximo: estado.disponibles,
      ),
    );
    if (elegidos != null && mounted) _controlador.agregarRecuerdos(elegidos);
  }

  Future<void> _capturarAhora(TipoElemento tipo) async {
    final recuerdo = await capturarRecuerdo(context, tipo);
    if (recuerdo != null && mounted) _controlador.agregarRecuerdos([recuerdo]);
  }

  Future<void> _elegirFecha() async {
    final ahora = ref.read(proveedorReloj)();
    final actual = ref.read(proveedorControladorEditarCapsula).fechaApertura;
    final elegida = await elegirFechaHoraApertura(
      context,
      ahora: ahora,
      fechaActual: actual,
    );
    if (elegida != null && mounted) _controlador.elegirFecha(elegida);
  }

  Future<void> _guardar() async {
    FocusScope.of(context).unfocus();
    final ok = await _controlador.guardar(
      idCapsula: widget.idCapsula,
      titulo: _titulo.text,
      mensaje: _mensaje.text,
    );
    if (!ok || !mounted) return;
    mostrarAvisoInformativo(context, 'Cambios guardados.');
    if (context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(proveedorControladorEditarCapsula, (anterior, siguiente) {
      final error = siguiente.error;
      if (error != null && error != anterior?.error) {
        mostrarAvisoError(context, error);
        _controlador.limpiarError();
      }
    });

    final capsula = ref.watch(proveedorCapsula(widget.idCapsula));
    final estado = ref.watch(proveedorControladorEditarCapsula);

    return PantallaCapsoul(
      appBar: AppBarCapsoul(titulo: const Text('Editar cápsula')),
      cuerpo: capsula.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (datos) {
          if (datos == null) {
            return const Center(child: Text('No puedes editar esta cápsula.'));
          }
          final editable = datos.estado == EstadoCapsula.borrador ||
              datos.estado == EstadoCapsula.programada;
          if (!editable) {
            return const Center(
              child: Text('Esta cápsula ya no se puede editar.'),
            );
          }
          if (!estado.inicializado || !_camposTextoCargados) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              if (!ref.read(proveedorControladorEditarCapsula).inicializado) {
                _controlador.cargarDesde(
                  recuerdos: datos.elementos,
                  fechaApertura: datos.fechaApertura,
                  destinatariosUsuarioIds: datos.destinatariosUsuarioIds,
                  imagenClave: datos.imagenClave,
                );
              }
              if (!_camposTextoCargados) {
                _camposTextoCargados = true;
                _titulo.text = datos.titulo;
                _mensaje.text = datos.mensaje ?? '';
              }
            });
            return const Center(child: CircularProgressIndicator());
          }

          final uid = ref.watch(
            proveedorEstadoAutenticacion.select((e) => e.value?.uid),
          );
          final fecha = estado.fechaApertura;
          final total = estado.recuerdos.length;
          final puedeAgregar = !estado.llena && !estado.guardando;

          return ListView(
            key: const Key('formulario-editar-capsula'),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              Text(
                'Recuerdos ($total/${EstadoEditarCapsula.maximo})',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: ColoresApp.primario,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              for (final recuerdo in estado.recuerdos)
                TarjetaRecuerdoElegido(
                  key: ValueKey(recuerdo.id),
                  recuerdo: recuerdo,
                  alQuitar: estado.guardando
                      ? null
                      : () => _controlador.quitar(recuerdo.id),
                ),
              OutlinedButton.icon(
                onPressed: puedeAgregar ? _elegirDeMisRecuerdos : null,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Elegir de mis recuerdos'),
              ),
              const SizedBox(height: 12),
              const Text(
                'Capturar ahora',
                style: TextStyle(color: ColoresApp.atenuado),
              ),
              const SizedBox(height: 8),
              BotonesAgregarElemento(
                habilitado: puedeAgregar,
                alElegir: _capturarAhora,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _titulo,
                enabled: !estado.guardando,
                maxLength: ValidadorCapsula.caracteresMaxTitulo,
                decoration: const InputDecoration(labelText: 'Título'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _mensaje,
                enabled: !estado.guardando,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(labelText: 'Mensaje'),
              ),
              const SizedBox(height: 16),
              Text(
                'Imagen de la capsula',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: ColoresApp.primario,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              SelectorImagenCapsula(
                seleccionada: estado.imagenClave,
                deshabilitado: estado.guardando,
                alElegir: _controlador.elegirImagen,
              ),
              const SizedBox(height: 16),
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Fecha de apertura',
                  contentPadding: EdgeInsets.zero,
                ),
                child: ListTile(
                  key: const Key('campo-fecha'),
                  leading: const Icon(Icons.lock_clock_outlined,
                      color: ColoresApp.acento),
                  title: Text(textoFechaHoraApertura(fecha)),
                  trailing: const Icon(Icons.calendar_month_outlined),
                  onTap: estado.guardando ? null : _elegirFecha,
                ),
              ),
              const SizedBox(height: 16),
              InterruptorCapsulaParaMi(
                seleccionados: estado.destinatariosUsuarioIds,
                uidActual: uid,
                deshabilitado: estado.guardando,
                alCambiar: _controlador.elegirDestinatarios,
              ),
              SelectorDestinatariosAmigos(
                seleccionados: estado.destinatariosUsuarioIds,
                deshabilitado: estado.guardando,
                alCambiar: _controlador.elegirDestinatarios,
              ),
              const SizedBox(height: 28),
              BotonPrincipal(
                etiqueta: 'Guardar cambios',
                cargando: estado.guardando,
                alPresionar: _guardar,
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () =>
                    context.push(RutasApp.detalleCapsulaDe(widget.idCapsula)),
                child: const Text('Volver al detalle'),
              ),
            ],
          );
        },
      ),
    );
  }
}
