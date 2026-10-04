import 'package:flutter/foundation.dart';

import '../../elementos/dominio/tipo_elemento.dart';
import 'momento.dart';

/// Filtro en memoria para momentos del perfil (texto y tipo de portada).
@immutable
class FiltroMomentos {
  const FiltroMomentos({this.consulta = '', this.tipoPortada});

  final String consulta;
  final TipoElemento? tipoPortada;

  bool get esVacio => consulta.trim().isEmpty && tipoPortada == null;

  FiltroMomentos conConsulta(String texto) =>
      FiltroMomentos(consulta: texto, tipoPortada: tipoPortada);

  FiltroMomentos conTipo(TipoElemento? tipo) =>
      FiltroMomentos(consulta: consulta, tipoPortada: tipo);

  bool admite(Momento momento) {
    final busqueda = consulta.trim().toLowerCase();
    if (busqueda.isNotEmpty) {
      final titulo = momento.titulo.toLowerCase();
      final descripcion = momento.descripcion?.toLowerCase() ?? '';
      if (!titulo.contains(busqueda) && !descripcion.contains(busqueda)) {
        return false;
      }
    }
    final tipo = tipoPortada;
    if (tipo != null) {
      final portada = momento.portada;
      if (portada == null || portada.tipo != tipo) return false;
    }
    return true;
  }

  List<Momento> aplicar(List<Momento> momentos) =>
      momentos.where(admite).toList(growable: false);
}
