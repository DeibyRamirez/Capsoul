import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/componentes/avisos_emergentes.dart';
import '../aplicacion/controlador_recuerdos.dart';
import '../aplicacion/proveedores_recuerdos.dart';
import '../dominio/fallo_recuerdo.dart';
import '../dominio/recuerdo.dart';

/// Confirma y borra un recuerdo; avisa si está en cápsulas selladas.
Future<void> borrarRecuerdoConConfirmacion(
  BuildContext context,
  WidgetRef ref,
  Recuerdo recuerdo, {
  VoidCallback? alExito,
}) async {
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
    await _avisarNoSePuedeBorrar(context, selladas);
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
    alExito?.call();
    return;
  }
  final error = ref.read(proveedorControladorRecuerdos).error;
  controlador.limpiarError();
  if (error is FalloRecuerdo &&
      error.codigo == FalloRecuerdo.codigoEnCapsulaSellada) {
    await _avisarNoSePuedeBorrar(context, 1);
  } else {
    mostrarAvisoError(context, error);
  }
}

Future<void> _avisarNoSePuedeBorrar(BuildContext context, int capsulas) {
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
