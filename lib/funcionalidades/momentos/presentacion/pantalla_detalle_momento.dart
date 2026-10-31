import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../nucleo/componentes/avisos_emergentes.dart';
import '../../../nucleo/componentes/cabecera_detalle_capsoul.dart';
import '../../../nucleo/componentes/menu_acciones_entidad.dart';
import '../../../nucleo/enrutador/rutas_app.dart';
import '../../../nucleo/errores/fallo_app.dart';
import '../../../nucleo/formato/fechas.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../../../nucleo/tema/tema_app.dart';
import '../../autenticacion/aplicacion/proveedores_autenticacion.dart';
import '../../inicio/aplicacion/proveedores_inicio.dart';
import '../../recuerdos/presentacion/navegacion_visor_recuerdo.dart';
import '../aplicacion/proveedores_momentos.dart';
import '../dominio/momento.dart';
import 'componentes/rejilla_bento.dart';

/// Detalle de un momento: portada, nombre, descripción y rejilla bento.
class PantallaDetalleMomento extends ConsumerWidget {
  const PantallaDetalleMomento({super.key, required this.idMomento});

  final String idMomento;

  Future<void> _borrar(BuildContext context, WidgetRef ref, Momento m) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('¿Borrar este momento?'),
        content: const Text(
          'Tus recuerdos no se borran: siguen en tu banco de recuerdos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (confirmado != true || !context.mounted) return;
    try {
      await ref.read(proveedorRepositorioMomentos).eliminar(m.id);
      ref
        ..invalidate(proveedorMomentos)
        ..invalidate(proveedorResumenInicio);
      if (!context.mounted) return;
      mostrarAvisoInformativo(context, 'Momento borrado.');
      context.pop();
    } catch (error) {
      if (context.mounted) mostrarAvisoError(context, error);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final momento = ref.watch(proveedorMomento(idMomento));
    final uid = ref.watch(
      proveedorEstadoAutenticacion.select((estado) => estado.value?.uid),
    );
    return Scaffold(
      backgroundColor: ColoresApp.superficie,
      body: momento.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _Mensaje(mensajeParaUsuario(error)),
        data: (m) {
          if (m == null) {
            return const _Mensaje('Este momento no existe o no puedes verlo.');
          }
          final cantidad = m.cantidad;
          final subtitulo =
              '${cantidad == 1 ? '1 recuerdo' : '$cantidad recuerdos'} · '
              '${formatearFechaCorta(m.creadoEn.toLocal())}';
          return Column(
            children: [
              CabeceraDetalleCapsoul(
                titulo: m.titulo,
                subtitulo: subtitulo,
                trailing: m.autorId == uid
                    ? MenuAccionesEntidad(
                        key: const Key('menu-acciones-momento'),
                        compacto: true,
                        puedeEditar: true,
                        puedeEliminar: true,
                        pedirConfirmacionEliminar: false,
                        etiquetaEliminar: 'Borrar momento',
                        tituloConfirmacion: '¿Borrar este momento?',
                        mensajeConfirmacion:
                            'Tus recuerdos no se borran: siguen en tu banco.',
                        alEditar: () => context.push(
                          RutasApp.editarMomentoDe(m.id),
                        ),
                        alEliminar: () => _borrar(context, ref, m),
                      )
                    : null,
              ),
              Expanded(child: _Contenido(momento: m)),
            ],
          );
        },
      ),
    );
  }
}

class _Contenido extends ConsumerWidget {
  const _Contenido({required this.momento});

  final Momento momento;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estilos = Theme.of(context).textTheme;
    final descripcion = momento.descripcion;
    final cantidad = momento.recuerdos.length;
    final subtituloElementos = cantidad == 1
        ? '1 elemento'
        : '$cantidad elementos';
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        if (descripcion != null && descripcion.isNotEmpty) ...[
          DecoratedBox(
            decoration: BoxDecoration(
              color: ColoresApp.fondoInicio,
              borderRadius: BorderRadius.circular(TemaApp.radioMediano),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(descripcion, style: estilos.bodyLarge),
            ),
          ),
          const SizedBox(height: 24),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                'Elementos',
                style: estilos.titleMedium?.copyWith(
                  fontFamily: TemaApp.fuenteTitulos,
                  color: ColoresApp.primario,
                ),
              ),
            ),
            Text(
              subtituloElementos,
              style: estilos.bodyMedium?.copyWith(color: ColoresApp.atenuado),
            ),
          ],
        ),
        const SizedBox(height: 12),
        RejillaBento(
          recuerdos: momento.recuerdos,
          alTocar: (recuerdo) =>
              mostrarVisorPublicacionRecuerdo(context, ref, recuerdo),
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
