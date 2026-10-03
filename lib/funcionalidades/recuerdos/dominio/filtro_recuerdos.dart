import 'package:flutter/foundation.dart';

import '../../elementos/dominio/tipo_elemento.dart';
import 'recuerdo.dart';

/// Filtro del banco de recuerdos por tipo y rango de fechas del recuerdo
/// (ambos extremos incluidos, solo el día).
@immutable
class FiltroRecuerdos {
  const FiltroRecuerdos({this.tipos = const {}, this.desde, this.hasta});

  static const FiltroRecuerdos todos = FiltroRecuerdos();

  /// Tipos aceptados; vacío = todos.
  final Set<TipoElemento> tipos;
  final DateTime? desde;
  final DateTime? hasta;

  bool get tieneFechas => desde != null || hasta != null;
  bool get esVacio => tipos.isEmpty && !tieneFechas;

  /// Recuerdos de los últimos [dias] días contando [hoy].
  factory FiltroRecuerdos.ultimosDias(int dias, DateTime hoy) {
    final fin = soloDia(hoy);
    return FiltroRecuerdos(
      desde: DateTime(fin.year, fin.month, fin.day - (dias - 1)),
      hasta: fin,
    );
  }

  /// Recuerdos del año de [hoy].
  factory FiltroRecuerdos.esteAnio(DateTime hoy) => FiltroRecuerdos(
        desde: DateTime(hoy.year),
        hasta: soloDia(hoy),
      );

  static DateTime soloDia(DateTime fecha) =>
      DateTime(fecha.year, fecha.month, fecha.day);

  /// `true` si [recuerdo] pasa el filtro (misma regla que la consulta).
  bool admite(Recuerdo recuerdo) {
    if (tipos.isNotEmpty && !tipos.contains(recuerdo.tipo)) return false;
    final dia = soloDia(recuerdo.fechaRecuerdo);
    final inicio = desde;
    final fin = hasta;
    if (inicio != null && dia.isBefore(soloDia(inicio))) return false;
    if (fin != null && dia.isAfter(soloDia(fin))) return false;
    return true;
  }

  FiltroRecuerdos conTipos(Set<TipoElemento> tipos) =>
      FiltroRecuerdos(tipos: tipos, desde: desde, hasta: hasta);

  FiltroRecuerdos conFechas(DateTime? desde, DateTime? hasta) =>
      FiltroRecuerdos(tipos: tipos, desde: desde, hasta: hasta);

  /// Activa o desactiva [tipo].
  FiltroRecuerdos alternarTipo(TipoElemento tipo) {
    final nuevos = {...tipos};
    if (!nuevos.remove(tipo)) nuevos.add(tipo);
    return conTipos(nuevos);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FiltroRecuerdos &&
          setEquals(other.tipos, tipos) &&
          other.desde == desde &&
          other.hasta == hasta;

  @override
  int get hashCode =>
      Object.hash(Object.hashAllUnordered(tipos), desde, hasta);

  @override
  String toString() =>
      'FiltroRecuerdos(${tipos.map((t) => t.valorBd).join(',')}, $desde, $hasta)';
}
