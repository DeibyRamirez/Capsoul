import 'package:flutter/material.dart';

import '../../dominio/validador_capsula.dart';
import '../../dominio/apertura_capsula.dart';

/// Elige día (desde mañana) y hora de apertura en hora local.
Future<DateTime?> elegirFechaHoraApertura(
  BuildContext context, {
  required DateTime ahora,
  DateTime? fechaActual,
}) async {
  final primerDia = ValidadorCapsula.primerDiaSeleccionable(ahora);
  final base = fechaActual ?? DateTime(ahora.year + 1, ahora.month, ahora.day, 8);
  final elegida = await showDatePicker(
    context: context,
    helpText: 'Fecha de apertura',
    cancelText: 'Cancelar',
    confirmText: 'Elegir',
    firstDate: primerDia,
    lastDate: DateTime(ahora.year + 100, 12, 31),
    initialDate: DateTime(base.year, base.month, base.day),
  );
  if (elegida == null || !context.mounted) return null;

  final horaInicial = TimeOfDay(hour: base.hour, minute: base.minute);
  final hora = await showTimePicker(
    context: context,
    helpText: 'Hora de apertura',
    cancelText: 'Cancelar',
    confirmText: 'Elegir',
    initialTime: horaInicial,
  );
  if (hora == null || !context.mounted) return null;

  return DateTime(elegida.year, elegida.month, elegida.day, hora.hour, hora.minute);
}

/// Texto corto para el campo de fecha/hora en formularios.
String textoFechaHoraApertura(DateTime? fecha) {
  if (fecha == null) return 'Elige cuándo se abrirá';
  final hora = '${fecha.hour.toString().padLeft(2, '0')}:'
      '${fecha.minute.toString().padLeft(2, '0')}';
  return 'Se abrirá el ${formatearFechaCorta(fecha)} a las $hora';
}
