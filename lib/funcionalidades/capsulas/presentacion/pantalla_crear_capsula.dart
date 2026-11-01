import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../nucleo/componentes/avisos_emergentes.dart';
import '../../../nucleo/componentes/boton_principal.dart';
import '../../../nucleo/componentes/cabecera_detalle_capsoul.dart';
import '../../../nucleo/componentes/pantalla_capsoul.dart';
import '../../../nucleo/componentes/tarjeta_capsoul.dart';
import '../../../nucleo/enrutador/rutas_app.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../../autenticacion/aplicacion/proveedores_autenticacion.dart';
import '../../elementos/dominio/tipo_elemento.dart';
import '../../recuerdos/dominio/recuerdo.dart';
import '../../recuerdos/presentacion/componentes/hoja_nuevo_recuerdo.dart';
import '../../recuerdos/presentacion/pantalla_elegir_recuerdos.dart';
import '../aplicacion/controlador_crear_capsula.dart';
import '../aplicacion/proveedores_capsulas.dart';
import '../dominio/validador_capsula.dart';
import 'componentes/botones_agregar_elemento.dart';
import 'componentes/elegir_fecha_hora_apertura.dart';
import 'componentes/interruptor_capsula_para_mi.dart';
import 'componentes/selector_destinatarios_amigos.dart';
import 'componentes/selector_imagen_capsula.dart';
import 'componentes/tarjeta_recuerdo_elegido.dart';

/// Formulario "Nueva cápsula": recuerdos del banco (hasta 10), título,
/// mensaje, fecha de apertura futura y amigo destinatario.
class PantallaCrearCapsula extends ConsumerStatefulWidget {
  const PantallaCrearCapsula({super.key});

  @override
  ConsumerState<PantallaCrearCapsula> createState() =>
      _EstadoPantallaCrearCapsula();
}

class _EstadoPantallaCrearCapsula extends ConsumerState<PantallaCrearCapsula> {
  final _titulo = TextEditingController();
  final _mensaje = TextEditingController();
  @override
  void dispose() {
    _titulo.dispose();
    _mensaje.dispose();
    super.dispose();
  }

  ControladorCrearCapsula get _controlador =>
      ref.read(proveedorControladorCrearCapsula.notifier);

  /// Abre el banco de recuerdos en modo selección.
  Future<void> _elegirDeMisRecuerdos() async {
    final estado = ref.read(proveedorControladorCrearCapsula);
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

  /// Captura un recuerdo nuevo, lo guarda en el banco y lo agrega.
  Future<void> _capturarAhora(TipoElemento tipo) async {
    final recuerdo = await capturarRecuerdo(context, tipo);
    if (recuerdo != null && mounted) _controlador.agregarRecuerdos([recuerdo]);
  }

  Future<void> _elegirFecha() async {
    final ahora = ref.read(proveedorReloj)();
    final actual = ref.read(proveedorControladorCrearCapsula).fechaApertura;
    final elegida = await elegirFechaHoraApertura(
      context,
      ahora: ahora,
      fechaActual: actual,
    );
    if (elegida != null && mounted) _controlador.elegirFecha(elegida);
  }

  Future<void> _guardar() async {
    FocusScope.of(context).unfocus();
    final id = await _controlador.guardar(
      titulo: _titulo.text,
      mensaje: _mensaje.text,
    );
    if (id == null || !mounted) return;
    mostrarAvisoInformativo(context, 'Tu cápsula quedó guardada.');
    context.pushReplacement(RutasApp.detalleCapsulaDe(id));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(proveedorControladorCrearCapsula, (anterior, siguiente) {
      final error = siguiente.error;
      if (error != null && error != anterior?.error) {
        mostrarAvisoError(context, error);
        _controlador.limpiarError();
      }
    });
    final estado = ref.watch(proveedorControladorCrearCapsula);
    final uid = ref.watch(
      proveedorEstadoAutenticacion.select((e) => e.value?.uid),
    );
    final fecha = estado.fechaApertura;
    final total = estado.recuerdos.length;
    final puedeAgregar = !estado.llena && !estado.guardando;

    return PantallaCapsoul(
      usarAreaSegura: false,
      cuerpo: Column(
        children: [
          const CabeceraDetalleCapsoul(
            titulo: 'Nueva cápsula',
            subtitulo: 'Elige recuerdos guardados o captura uno nuevo.',
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: ListView(
                key: const Key('formulario-capsula'),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                children: [
                  TarjetaCapsoul(
                    icono: Icons.photo_library_outlined,
                    titulo: 'Recuerdos ($total/${EstadoCrearCapsula.maximo})',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final recuerdo in estado.recuerdos)
                          TarjetaRecuerdoElegido(
                            key: ValueKey(recuerdo.id),
                            recuerdo: recuerdo,
                            alQuitar: estado.guardando
                                ? null
                                : () => _controlador.quitar(recuerdo.id),
                          ),
                        OutlinedButton.icon(
                          key: const Key('boton-elegir-recuerdos'),
                          onPressed: puedeAgregar
                              ? _elegirDeMisRecuerdos
                              : null,
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('Elegir de mis recuerdos'),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Capturar ahora',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: ColoresApp.atenuado),
                        ),
                        const SizedBox(height: 8),
                        BotonesAgregarElemento(
                          habilitado: puedeAgregar,
                          alElegir: _capturarAhora,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TarjetaCapsoul(
                    icono: Icons.edit_outlined,
                    titulo: 'Título y mensaje',
                    child: Column(
                      children: [
                        TextField(
                          key: const Key('campo-titulo'),
                          controller: _titulo,
                          enabled: !estado.guardando,
                          maxLength: ValidadorCapsula.caracteresMaxTitulo,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            labelText: 'Título',
                            hintText: 'Para …',
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          key: const Key('campo-mensaje'),
                          controller: _mensaje,
                          enabled: !estado.guardando,
                          minLines: 3,
                          maxLines: 6,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            labelText: 'Mensaje',
                            hintText:
                                'Cuéntale por qué guardas esto para el futuro',
                            alignLabelWithHint: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TarjetaCapsoul(
                    icono: Icons.image_outlined,
                    titulo: 'Imagen de la cápsula',
                    child: SelectorImagenCapsula(
                      seleccionada: estado.imagenClave,
                      deshabilitado: estado.guardando,
                      alElegir: _controlador.elegirImagen,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TarjetaCapsoul(
                    icono: Icons.lock_clock_outlined,
                    titulo: 'Apertura y destinatarios',
                    child: Column(
                      children: [
                        _CampoFecha(
                          texto: textoFechaHoraApertura(fecha),
                          alTocar: estado.guardando ? null : _elegirFecha,
                        ),
                        const SizedBox(height: 8),
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  BotonPrincipal(
                    etiqueta: 'Guardar cápsula',
                    cargando: estado.guardando,
                    alPresionar: _guardar,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CampoFecha extends StatelessWidget {
  const _CampoFecha({required this.texto, required this.alTocar});

  final String texto;
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Fecha de apertura',
        contentPadding: EdgeInsets.zero,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          key: const Key('campo-fecha'),
          leading: const Icon(
            Icons.lock_clock_outlined,
            color: ColoresApp.acento,
          ),
          title: Text(texto),
          trailing: const Icon(Icons.calendar_month_outlined),
          onTap: alTocar,
        ),
      ),
    );
  }
}
