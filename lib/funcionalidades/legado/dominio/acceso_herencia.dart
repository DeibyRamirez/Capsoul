import 'package:flutter/foundation.dart';

import 'condicion_herencia.dart';
import 'estado_herencia.dart';

/// Herencia que custodio como persona de confianza.
@immutable
class HerenciaACuidado {
  const HerenciaACuidado({
    required this.id,
    required this.titulo,
    required this.estado,
    required this.condicionActivacion,
    required this.propietarioId,
    required this.propietarioNombre,
    required this.contenidoVisible,
    required this.accesoActivo,
    this.fechaActivacion,
    this.accesoExpiraEn,
    this.nCapsulas = 0,
    this.creadoEn,
  });

  final String id;
  final String titulo;
  final EstadoHerencia estado;
  final CondicionHerencia condicionActivacion;
  final DateTime? fechaActivacion;
  final String propietarioId;
  final String propietarioNombre;
  final bool contenidoVisible;
  final bool accesoActivo;
  final DateTime? accesoExpiraEn;
  final int nCapsulas;
  final DateTime? creadoEn;

  factory HerenciaACuidado.desdeFila(Map<String, dynamic> fila) {
    return HerenciaACuidado(
      id: fila['id'] as String,
      titulo: fila['titulo'] as String? ?? 'Pequeña herencia',
      estado: EstadoHerencia.desdeBd(fila['estado'] as String?) ??
          EstadoHerencia.activa,
      condicionActivacion: CondicionHerencia.desdeBd(
            fila['condicion_activacion'] as String?,
          ) ??
          CondicionHerencia.fecha,
      fechaActivacion: _fecha(fila['fecha_activacion']),
      propietarioId: fila['propietario_id'] as String? ?? '',
      propietarioNombre: fila['propietario_nombre'] as String? ?? 'Alguien',
      contenidoVisible: fila['contenido_visible'] as bool? ?? false,
      accesoActivo: fila['acceso_activo'] as bool? ?? false,
      accesoExpiraEn: _fecha(fila['acceso_expira_en']),
      nCapsulas: fila['n_capsulas'] as int? ?? 0,
      creadoEn: _fecha(fila['creado_en']),
    );
  }

  static DateTime? _fecha(Object? v) =>
      v is String ? DateTime.tryParse(v) : null;
}

/// Estado del acceso de la persona de confianza a una herencia.
@immutable
class EstadoAccesoHerencia {
  const EstadoAccesoHerencia({
    this.esConfianza = false,
    this.liberada = false,
    this.accesoActivo = false,
    this.accesoExpiraEn,
    this.codigoVigente = false,
    this.codigoExpiraEn,
    this.intentosRestantes,
    this.bloqueadoHasta,
    this.reenvioDisponibleEn,
  });

  final bool esConfianza;
  final bool liberada;
  final bool accesoActivo;
  final DateTime? accesoExpiraEn;
  final bool codigoVigente;
  final DateTime? codigoExpiraEn;
  final int? intentosRestantes;
  final DateTime? bloqueadoHasta;
  final DateTime? reenvioDisponibleEn;

  bool get bloqueado =>
      bloqueadoHasta != null && bloqueadoHasta!.isAfter(DateTime.now());

  bool get puedeReenviar =>
      reenvioDisponibleEn == null ||
      !reenvioDisponibleEn!.isAfter(DateTime.now());

  factory EstadoAccesoHerencia.desdeJson(Map<String, dynamic>? json) {
    if (json == null) return const EstadoAccesoHerencia();
    return EstadoAccesoHerencia(
      esConfianza: json['es_confianza'] as bool? ?? false,
      liberada: json['liberada'] as bool? ?? false,
      accesoActivo: json['acceso_activo'] as bool? ?? false,
      accesoExpiraEn: _fecha(json['acceso_expira_en']),
      codigoVigente: json['codigo_vigente'] as bool? ?? false,
      codigoExpiraEn: _fecha(json['codigo_expira_en']),
      intentosRestantes: _entero(json['intentos_restantes']),
      bloqueadoHasta: _fecha(json['bloqueado_hasta']),
      reenvioDisponibleEn: _fecha(json['reenvio_disponible_en']),
    );
  }

  static DateTime? _fecha(Object? v) =>
      v is String ? DateTime.tryParse(v) : null;

  static int? _entero(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }
}

/// Resultado de validar el código de acceso de una herencia.
@immutable
class ResultadoValidacionCodigo {
  const ResultadoValidacionCodigo({
    required this.ok,
    this.codigoError,
    this.mensaje,
    this.accesoExpiraEn,
    this.intentosRestantes,
    this.bloqueadoHasta,
  });

  final bool ok;
  final String? codigoError;
  final String? mensaje;
  final DateTime? accesoExpiraEn;
  final int? intentosRestantes;
  final DateTime? bloqueadoHasta;

  factory ResultadoValidacionCodigo.desdeJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const ResultadoValidacionCodigo(
        ok: false,
        codigoError: 'respuesta_invalida',
      );
    }
    return ResultadoValidacionCodigo(
      ok: json['ok'] as bool? ?? false,
      codigoError: json['codigo'] as String?,
      mensaje: json['mensaje'] as String?,
      accesoExpiraEn: _fecha(json['acceso_expira_en']),
      intentosRestantes: _entero(json['intentos_restantes']),
      bloqueadoHasta: _fecha(json['bloqueado_hasta']),
    );
  }

  static DateTime? _fecha(Object? v) =>
      v is String ? DateTime.tryParse(v) : null;

  static int? _entero(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }
}
