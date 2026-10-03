import 'capsula.dart';
import 'estado_capsula.dart';

/// Cómo se presenta una cápsula a quien la mira.
enum ModoApertura {
  /// Fecha futura y quien mira no es el autor: candado, sin contenido.
  bloqueada,

  /// Fecha futura y quien mira es el autor: candado y cuenta regresiva, pero
  /// puede ver su propio contenido.
  selladaParaAutor,

  /// La fecha llegó (o el servidor la liberó): se puede abrir.
  lista,
}

/// Regla pura de apertura.
ModoApertura calcularModoApertura(
  Capsula capsula, {
  required String? uidActual,
  required DateTime ahora,
}) {
  final fecha = capsula.fechaApertura;
  final llego = capsula.estado == EstadoCapsula.liberada ||
      (fecha != null && !fecha.isAfter(ahora));
  if (llego) return ModoApertura.lista;
  return capsula.autorId == uidActual
      ? ModoApertura.selladaParaAutor
      : ModoApertura.bloqueada;
}

const List<String> _mesesAbreviados = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
];

/// "13 ago 2046" (hora local).
String formatearFechaCorta(DateTime fecha) {
  final local = fecha.toLocal();
  return '${local.day} ${_mesesAbreviados[local.month - 1]} ${local.year}';
}

/// Años, meses y días completos entre [desde] y [hasta] (calendario).
({int anios, int meses, int dias}) diferenciaCalendario(
  DateTime desde,
  DateTime hasta,
) {
  if (!hasta.isAfter(desde)) return (anios: 0, meses: 0, dias: 0);
  var meses = (hasta.year - desde.year) * 12 + hasta.month - desde.month;
  var ancla = _sumarMeses(desde, meses);
  if (ancla.isAfter(hasta)) {
    meses--;
    ancla = _sumarMeses(desde, meses);
  }
  final dias = hasta.difference(ancla).inDays;
  return (anios: meses ~/ 12, meses: meses % 12, dias: dias);
}

DateTime _sumarMeses(DateTime fecha, int meses) {
  final total = fecha.month - 1 + meses;
  final anio = fecha.year + total ~/ 12;
  final mes = total % 12 + 1;
  final ultimoDia = DateTime(anio, mes + 1, 0).day;
  return DateTime(
    anio,
    mes,
    fecha.day > ultimoDia ? ultimoDia : fecha.day,
    fecha.hour,
    fecha.minute,
    fecha.second,
  );
}

String _plural(int n, String singular, String plural) =>
    '$n ${n == 1 ? singular : plural}';

/// "Mensaje para dentro de 20 años" según la distancia entre la creación y
/// la apertura.
String describirHorizonte(DateTime creadoEn, DateTime fechaApertura) {
  final d = diferenciaCalendario(creadoEn, fechaApertura);
  final texto = d.anios > 0
      ? _plural(d.anios, 'año', 'años')
      : d.meses > 0
          ? _plural(d.meses, 'mes', 'meses')
          : _plural(d.dias < 1 ? 1 : d.dias, 'día', 'días');
  return 'Mensaje para dentro de $texto';
}

/// Cuenta regresiva legible: "Faltan 19 años, 10 meses y 3 días",
/// "Faltan 5 h 12 min", "Falta menos de un minuto".
String describirTiempoRestante(DateTime ahora, DateTime fechaApertura) {
  if (!fechaApertura.isAfter(ahora)) return 'Ya puedes abrirla';
  final restante = fechaApertura.difference(ahora);
  if (restante.inHours < 24) {
    if (restante.inMinutes < 1) return 'Falta menos de un minuto';
    final horas = restante.inHours;
    final minutos = restante.inMinutes.remainder(60);
    return horas > 0 ? 'Faltan $horas h $minutos min' : 'Faltan $minutos min';
  }
  final d = diferenciaCalendario(ahora, fechaApertura);
  final partes = [
    if (d.anios > 0) _plural(d.anios, 'año', 'años'),
    if (d.meses > 0) _plural(d.meses, 'mes', 'meses'),
    if (d.dias > 0) _plural(d.dias, 'día', 'días'),
  ];
  if (partes.isEmpty) return 'Falta 1 día';
  final unidas = partes.length == 1
      ? partes.first
      : '${partes.sublist(0, partes.length - 1).join(', ')} y ${partes.last}';
  final soloUnDia = partes.length == 1 && partes.first.startsWith('1 ');
  return '${soloUnDia ? 'Falta' : 'Faltan'} $unidas';
}
