import 'package:flutter/foundation.dart';

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
  final String? valorAproximado;
  final String moneda;
  final String? instrucciones;
  final String? mensajePersonal;

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
      valorAproximado: json['valor_aproximado'] as String?,
      moneda: json['moneda'] as String? ?? 'COP',
      instrucciones: json['instrucciones'] as String?,
      mensajePersonal: json['mensaje_personal'] as String?,
    );
  }
}
