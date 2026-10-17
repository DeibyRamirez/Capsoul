import 'package:flutter/foundation.dart';

import 'condicion_herencia.dart';
import 'estado_herencia.dart';
import 'metadatos_herencia.dart';

@immutable
class Herencia {
  const Herencia({
    required this.id,
    required this.titulo,
    required this.estado,
    required this.condicionActivacion,
    this.descripcion,
    this.beneficiarioUsuarioId,
    this.beneficiarioCorreo,
    this.personaConfianzaId,
    this.fechaActivacion,
    this.diasInactividad,
    this.metadatos = const MetadatosHerencia(),
    this.creadoEn,
  });

  final String id;
  final String titulo;
  final String? descripcion;
  final String? beneficiarioUsuarioId;
  final String? beneficiarioCorreo;
  final String? personaConfianzaId;
  final CondicionHerencia condicionActivacion;
  final DateTime? fechaActivacion;
  final int? diasInactividad;
  final EstadoHerencia estado;
  final MetadatosHerencia metadatos;
  final DateTime? creadoEn;

  factory Herencia.desdeFila(Map<String, dynamic> fila) {
    final metadatosRaw = fila['metadatos'];
    return Herencia(
      id: fila['id'] as String,
      titulo: fila['titulo'] as String,
      descripcion: fila['descripcion'] as String?,
      beneficiarioUsuarioId: fila['beneficiario_usuario_id'] as String?,
      beneficiarioCorreo: fila['beneficiario_correo'] as String?,
      personaConfianzaId: fila['persona_confianza_id'] as String?,
      condicionActivacion: CondicionHerencia.desdeBd(
            fila['condicion_activacion'] as String?,
          ) ??
          CondicionHerencia.confirmacionConfianza,
      fechaActivacion: _fecha(fila['fecha_activacion']),
      diasInactividad: fila['dias_inactividad'] as int?,
      estado: EstadoHerencia.desdeBd(fila['estado'] as String?) ??
          EstadoHerencia.borrador,
      metadatos: MetadatosHerencia.desdeJson(
        metadatosRaw is Map<String, dynamic>
            ? metadatosRaw
            : metadatosRaw is Map
                ? Map<String, dynamic>.from(metadatosRaw)
                : null,
      ),
      creadoEn: _fecha(fila['creado_en']),
    );
  }

  static DateTime? _fecha(Object? v) =>
      v is String ? DateTime.tryParse(v) : null;
}

@immutable
class CapsulaVinculadaHerencia {
  const CapsulaVinculadaHerencia({
    required this.capsulaId,
    required this.titulo,
    required this.estado,
    this.orden = 0,
  });

  final String capsulaId;
  final String titulo;
  final String estado;
  final int orden;

  factory CapsulaVinculadaHerencia.desdeJson(Map<String, dynamic> json) {
    return CapsulaVinculadaHerencia(
      capsulaId: json['capsula_id'] as String,
      titulo: json['titulo'] as String? ?? 'Cápsula',
      estado: json['estado'] as String? ?? 'programada',
      orden: json['orden'] as int? ?? 0,
    );
  }
}

@immutable
class DetalleHerencia {
  const DetalleHerencia({
    required this.herencia,
    this.elementoIds = const [],
    this.capsulas = const [],
  });

  final Herencia herencia;
  final List<String> elementoIds;
  final List<CapsulaVinculadaHerencia> capsulas;

  factory DetalleHerencia.desdeJson(Map<String, dynamic>? json) {
    if (json == null) {
      throw const FormatException('detalle_herencia_vacio');
    }
    final herenciaRaw = json['herencia'];
    if (herenciaRaw is! Map) {
      throw const FormatException('herencia_invalida');
    }
    final elementos = json['elementos'];
    final capsulas = json['capsulas'];
    return DetalleHerencia(
      herencia: Herencia.desdeFila(Map<String, dynamic>.from(herenciaRaw)),
      elementoIds: elementos is List
          ? [
              for (final e in elementos)
                if (e is Map) e['elemento_id'] as String? ?? '',
            ].where((id) => id.isNotEmpty).toList()
          : const [],
      capsulas: capsulas is List
          ? [
              for (final c in capsulas)
                if (c is Map)
                  CapsulaVinculadaHerencia.desdeJson(
                    Map<String, dynamic>.from(c),
                  ),
            ]
          : const [],
    );
  }
}
