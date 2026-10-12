import 'package:flutter/foundation.dart';

import 'estado_capsula.dart';

/// Resumen de una cápsula dirigida al usuario actual (`capsulas_recibidas`).
@immutable
class CapsulaRecibida {
  const CapsulaRecibida({
    required this.id,
    required this.autorId,
    required this.autorNombre,
    required this.fechaApertura,
    required this.estado,
    this.titulo,
    this.liberadaEn,
  });

  final String id;
  final String autorId;
  final String autorNombre;
  final String? titulo;
  final DateTime fechaApertura;
  final EstadoCapsula estado;
  final DateTime? liberadaEn;

  bool get estaLiberada => estado == EstadoCapsula.liberada;

  String get tituloVisible =>
      estaLiberada && titulo != null && titulo!.trim().isNotEmpty
          ? titulo!.trim()
          : 'Cápsula para ti';

  static CapsulaRecibida? desdeFilaRpc(Map<String, dynamic> fila) {
    final id = fila['capsula_id'];
    final autorId = fila['autor_id'];
    final autorNombre = fila['autor_nombre'];
    final fecha = fila['fecha_apertura'];
    final estado = EstadoCapsula.desdeValorBd(fila['estado']);
    if (id is! String ||
        autorId is! String ||
        autorNombre is! String ||
        fecha is! String ||
        estado == null) {
      return null;
    }
    final parsed = DateTime.tryParse(fecha);
    if (parsed == null) return null;
    final titulo = fila['titulo'];
    final liberada = fila['liberada_en'];
    return CapsulaRecibida(
      id: id,
      autorId: autorId,
      autorNombre: autorNombre.trim(),
      titulo: titulo is String ? titulo : null,
      fechaApertura: parsed,
      estado: estado,
      liberadaEn: liberada is String ? DateTime.tryParse(liberada) : null,
    );
  }
}
