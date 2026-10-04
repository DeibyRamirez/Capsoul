import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../nucleo/componentes/avisos_emergentes.dart';
import '../../../nucleo/componentes/cabecera_detalle_capsoul.dart';
import '../../../nucleo/errores/fallo_app.dart';
import '../../../nucleo/formato/fechas.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../../autenticacion/aplicacion/proveedores_autenticacion.dart';
import '../../elementos/dominio/validador_medios.dart';
import '../aplicacion/controlador_recuerdos.dart';
import '../aplicacion/proveedores_recuerdos.dart';
import '../dominio/fallo_recuerdo.dart';
import '../dominio/recuerdo.dart';
import 'componentes/vista_recuerdo.dart';

/// Detalle de un recuerdo: contenido, título, fecha, tamaño y "Borrar".
class PantallaDetalleRecuerdo extends ConsumerWidget {
  const PantallaDetalleRecuerdo({super.key, required this.idRecuerdo});

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
            : _Contenido(recuerdo: datos),
      ),
    );
  }
}

class _Contenido extends ConsumerWidget {
  const _Contenido({required this.recuerdo});

  final Recuerdo recuerdo;

  Future<void> _borrar(BuildContext context, WidgetRef ref) async {
    final repositorio = ref.read(proveedorRepositorioRecuerdos);
    int selladas;
    try {
      selladas = await repositorio.contarCapsulasSelladas(recuerdo.id);
    } catch (error) {
      if (context.mounted) mostrarAvisoError(context, error);
      return;
    }
    if (!context.mounted) return;
    if (selladas > 0) {
      await _avisarNoSePuede(context, selladas);
      return;
    }
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('¿Borrar este recuerdo?'),
        content: const Text(
          'Se quitará también de los momentos y de las cápsulas en borrador '
          'donde esté. No se puede deshacer.',
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
    final controlador = ref.read(proveedorControladorRecuerdos.notifier);
    final borrado = await controlador.eliminar(recuerdo);
    if (!context.mounted) return;
    if (borrado) {
      mostrarAvisoInformativo(context, 'Recuerdo borrado.');
      context.pop();
      return;
    }
    final error = ref.read(proveedorControladorRecuerdos).error;
    controlador.limpiarError();
    if (error is FalloRecuerdo &&
        error.codigo == FalloRecuerdo.codigoEnCapsulaSellada) {
      await _avisarNoSePuede(context, 1);
    } else {
      mostrarAvisoError(context, error);
    }
  }

  static Future<void> _avisarNoSePuede(BuildContext context, int capsulas) {
    return showDialog<void>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('No se puede borrar'),
        content: Text(
          capsulas == 1
              ? 'Este recuerdo está en una cápsula programada o abierta.'
              : 'Este recuerdo está en $capsulas cápsulas programadas o '
                  'abiertas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(
      proveedorEstadoAutenticacion.select((estado) => estado.value?.uid),
    );
    final ocupado = ref.watch(
      proveedorControladorRecuerdos.select((estado) => estado.ocupado),
    );
    final bytes = recuerdo.bytes;
    final duracion = recuerdo.duracion;
    final datos = [
      recuerdo.tipo.etiqueta,
      if (duracion != null) formatearDuracion(duracion),
      if (bytes != null) formatearBytes(bytes),
    ].join(' · ');
    return Column(
      children: [
        CabeceraDetalleCapsoul(
          titulo: recuerdo.nombre,
          subtitulo: formatearFechaCorta(recuerdo.fechaRecuerdo),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              VistaRecuerdo(recuerdo: recuerdo),
              const SizedBox(height: 12),
              Text(datos, style: const TextStyle(color: ColoresApp.atenuado)),
              if (recuerdo.propietarioId == uid) ...[
                const SizedBox(height: 32),
                OutlinedButton.icon(
                  key: const Key('boton-borrar-recuerdo'),
                  onPressed: ocupado ? null : () => _borrar(context, ref),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Borrar recuerdo'),
                ),
              ],
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
