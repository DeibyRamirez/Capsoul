import 'package:flutter/foundation.dart';

import 'condicion_herencia.dart';
import 'estado_herencia.dart';
import 'metadatos_herencia.dart';

/// Herencia que otra persona me asignó (`herencias_recibidas`).
@immutable
class HerenciaRecibida {
  const HerenciaRecibida({
    required this.id,
    required this.titulo,
    required this.estado,
    required this.condicionActivacion,
    required this.propietarioId,
    required this.propietarioNombre,
    required this.contenidoVisible,
    this.fechaActivacion,
    this.descripcion,
    this.metadatos = const MetadatosHerencia(),
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
  final String? descripcion;
  final MetadatosHerencia metadatos;
  final int nCapsulas;
  final DateTime? creadoEn;

  factory HerenciaRecibida.desdeFila(Map<String, dynamic> fila) {
    final metadatosRaw = fila['metadatos'];
    return HerenciaRecibida(
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
      descripcion: fila['descripcion'] as String?,
      metadatos: MetadatosHerencia.desdeJson(
        metadatosRaw is Map<String, dynamic>
            ? metadatosRaw
            : metadatosRaw is Map
                ? Map<String, dynamic>.from(metadatosRaw)
                : null,
      ),
      nCapsulas: fila['n_capsulas'] as int? ?? 0,
      creadoEn: _fecha(fila['creado_en']),
    );
  }

  static DateTime? _fecha(Object? v) =>
      v is String ? DateTime.tryParse(v) : null;
}

/// Herencia que me piden confirmar como persona de confianza.
@immutable
class HerenciaPorConfirmar {
  const HerenciaPorConfirmar({
    required this.id,
    required this.titulo,
    required this.propietarioId,
    required this.propietarioNombre,
    this.beneficiarioUsuarioId,
    this.beneficiarioNombre,
    this.creadoEn,
  });

  final String id;
  final String titulo;
  final String propietarioId;
  final String propietarioNombre;
  final String? beneficiarioUsuarioId;
  final String? beneficiarioNombre;
  final DateTime? creadoEn;

  factory HerenciaPorConfirmar.desdeFila(Map<String, dynamic> fila) {
    return HerenciaPorConfirmar(
      id: fila['id'] as String,
      titulo: fila['titulo'] as String? ?? 'Pequeña herencia',
      propietarioId: fila['propietario_id'] as String? ?? '',
      propietarioNombre: fila['propietario_nombre'] as String? ?? 'Alguien',
      beneficiarioUsuarioId: fila['beneficiario_usuario_id'] as String?,
      beneficiarioNombre: fila['beneficiario_nombre'] as String?,
      creadoEn: fila['creado_en'] is String
          ? DateTime.tryParse(fila['creado_en'] as String)
          : null,
    );
  }
}
