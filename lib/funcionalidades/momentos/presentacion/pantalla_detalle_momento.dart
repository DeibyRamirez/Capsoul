import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../nucleo/componentes/avisos_emergentes.dart';
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
    final datos = momento.value;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Momento'),
        actions: [
          if (datos != null && datos.autorId == uid)
            IconButton(
              key: const Key('boton-borrar-momento'),
              tooltip: 'Borrar momento',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _borrar(context, ref, datos),
            ),
        ],
      ),
      body: momento.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _Mensaje(mensajeParaUsuario(error)),
        data: (m) => m == null
            ? const _Mensaje('Este momento no existe o no puedes verlo.')
            : _Contenido(momento: m),
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
    final cantidad = momento.cantidad;
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
        const SizedBox(height: 16),
        Text(
          momento.titulo,
          style: estilos.headlineSmall?.copyWith(
            color: ColoresApp.primario,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${cantidad == 1 ? '1 recuerdo' : '$cantidad recuerdos'} · '
          '${formatearFechaCorta(momento.creadoEn.toLocal())}',
          style: const TextStyle(color: ColoresApp.atenuado),
        ),
        if (descripcion != null && descripcion.isNotEmpty) ...[
          const SizedBox(height: 12),
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
