import 'package:flutter/foundation.dart';

import '../dominio/referencia_musica.dart';

/// Estado inmutable de la pantalla de búsqueda de música.
@immutable
class EstadoBusquedaMusica {
  const EstadoBusquedaMusica({
    this.consulta = '',
    this.resultados = const [],
    this.cargando = false,
    this.error,
    this.consultaBuscada,
  });

  final String consulta;
  final List<ReferenciaMusica> resultados;
  final bool cargando;

  /// Mensaje en español si la última búsqueda falló.
  final String? error;

  /// Consulta de los [resultados] mostrados (null si aún no se buscó).
  final String? consultaBuscada;

  static const largoMinimo = 2;

  bool get consultaValida => consulta.length >= largoMinimo;

  bool get sinResultados =>
      !cargando &&
      error == null &&
      consultaBuscada != null &&
      resultados.isEmpty;

  EstadoBusquedaMusica copiarCon({
    String? consulta,
    List<ReferenciaMusica>? resultados,
    bool? cargando,
    String? error,
    bool quitarError = false,
    String? consultaBuscada,
  }) =>
      EstadoBusquedaMusica(
        consulta: consulta ?? this.consulta,
        resultados: resultados ?? this.resultados,
        cargando: cargando ?? this.cargando,
        error: quitarError ? null : (error ?? this.error),
        consultaBuscada: consultaBuscada ?? this.consultaBuscada,
      );
}
