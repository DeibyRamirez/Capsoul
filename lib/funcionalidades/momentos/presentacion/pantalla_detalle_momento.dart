import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../nucleo/componentes/avisos_emergentes.dart';
import '../../../nucleo/componentes/cabecera_detalle_capsoul.dart';
import '../../../nucleo/enrutador/rutas_app.dart';
import '../../../nucleo/errores/fallo_app.dart';
import '../../../nucleo/formato/fechas.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../../../nucleo/tema/tema_app.dart';
import '../../autenticacion/aplicacion/proveedores_autenticacion.dart';
import '../../inicio/aplicacion/proveedores_inicio.dart';
import '../../recuerdos/presentacion/componentes/miniatura_recuerdo_firmada.dart';
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
                    ? IconButton(
                        key: const Key('boton-borrar-momento'),
                        tooltip: 'Borrar momento',
                        icon: const Icon(
                          Icons.delete_outline,
                          color: ColoresApp.sobrePrimario,
                        ),
                        onPressed: () => _borrar(context, ref, m),
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

class _Contenido extends StatelessWidget {
  const _Contenido({required this.momento});

  final Momento momento;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    final portada = momento.portada;
    final descripcion = momento.descripcion;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        if (portada != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(TemaApp.radioGrande),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: MiniaturaRecuerdoFirmada(recuerdo: portada, tamanoIcono: 48),
            ),
          ),
        if (descripcion != null && descripcion.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(descripcion, style: estilos.bodyLarge),
        ],
        const SizedBox(height: 20),
        RejillaBento(
          recuerdos: momento.recuerdos,
          alTocar: (recuerdo) =>
              context.push(RutasApp.detalleRecuerdoDe(recuerdo.id)),
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
