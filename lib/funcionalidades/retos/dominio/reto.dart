import 'package:flutter/foundation.dart';

@immutable
class Reto {
  const Reto({
    required this.id,
    required this.slug,
    required this.titulo,
    required this.descripcion,
    required this.pasos,
    required this.orden,
    required this.criterioClave,
    required this.completado,
    this.completadoEn,
  });

  final String id;
  final String slug;
  final String titulo;
  final String? descripcion;
  final List<String> pasos;
  final int orden;
  final String criterioClave;
  final bool completado;
  final DateTime? completadoEn;
}
