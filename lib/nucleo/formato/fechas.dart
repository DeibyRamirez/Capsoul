const List<String> _mesesAbreviados = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
];

/// "13 ago 2046" (hora local).
String formatearFechaCorta(DateTime fecha) {
  final local = fecha.toLocal();
  return '${local.day} ${_mesesAbreviados[local.month - 1]} ${local.year}';
}
