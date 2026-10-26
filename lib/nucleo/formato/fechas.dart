const List<String> _mesesAbreviados = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
];

/// "13 ago 2046" (hora local).
String formatearFechaCorta(DateTime fecha) {
  final local = fecha.toLocal();
  return '${local.day} ${_mesesAbreviados[local.month - 1]} ${local.year}';
}

/// "13 ago 2046 · 08:30" (hora local).
String formatearFechaHora(DateTime fecha) {
  final local = fecha.toLocal();
  final hora = local.hour.toString().padLeft(2, '0');
  final minuto = local.minute.toString().padLeft(2, '0');
  return '${formatearFechaCorta(local)} · $hora:$minuto';
}
