import 'package:flutter/foundation.dart';

import '../../../nucleo/formato/valor_monetario.dart';

@immutable
class MetadatosHerencia {
  const MetadatosHerencia({
    this.tipoActivo,
    this.titular,
    this.valorAproximado,
    this.moneda = 'COP',
    this.instrucciones,
    this.mensajePersonal,
  });

  final String? tipoActivo;
  final String? titular;
  /// Valor entero (sin puntos). En UI se muestra con miles.
  final int? valorAproximado;
  final String moneda;
  final String? instrucciones;
  final String? mensajePersonal;

  String get valorFormateado {
    final v = valorAproximado;
    if (v == null) return '';
    return formatearMiles('$v');
  }

  Map<String, dynamic> aJson() => {
        if (tipoActivo != null) 'tipo_activo': tipoActivo,
        if (titular != null) 'titular': titular,
        if (valorAproximado != null) 'valor_aproximado': valorAproximado,
        'moneda': moneda,
        if (instrucciones != null) 'instrucciones': instrucciones,
        if (mensajePersonal != null) 'mensaje_personal': mensajePersonal,
      };

  factory MetadatosHerencia.desdeJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return const MetadatosHerencia();
    return MetadatosHerencia(
      tipoActivo: json['tipo_activo'] as String?,
      titular: json['titular'] as String?,
      valorAproximado: _entero(json['valor_aproximado']),
      moneda: json['moneda'] as String? ?? 'COP',
      instrucciones: json['instrucciones'] as String?,
      mensajePersonal: json['mensaje_personal'] as String?,
    );
  }

  static int? _entero(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return parsearEnteroMiles(v);
    return null;
  }
}
