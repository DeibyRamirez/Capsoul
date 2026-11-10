import 'package:flutter/foundation.dart';

import '../../elementos/dominio/elemento_borrador.dart';
import '../dominio/modo_captura.dart';

/// Estado de la UI del hub de cámara (sin el [CameraController]).
@immutable
class EstadoHubCaptura {
  const EstadoHubCaptura({
    this.modo = ModoCaptura.video,
    this.duracionMaxima = const Duration(seconds: 15),
    this.grabando = false,
    this.procesando = false,
    this.transcurrido = Duration.zero,
    this.capturaLista,
    this.bloquearModos = false,
  });

  final ModoCaptura modo;
  final Duration duracionMaxima;
  final bool grabando;
  final bool procesando;
  final Duration transcurrido;
  final ElementoBorrador? capturaLista;
  final bool bloquearModos;

  double get progresoGrabacion {
    if (duracionMaxima.inMilliseconds == 0) return 0;
    return transcurrido.inMilliseconds / duracionMaxima.inMilliseconds;
  }

  bool get enPreview => capturaLista != null;

  EstadoHubCaptura copyWith({
    ModoCaptura? modo,
    Duration? duracionMaxima,
    bool? grabando,
    bool? procesando,
    Duration? transcurrido,
    ElementoBorrador? capturaLista,
    bool limpiarCaptura = false,
    bool? bloquearModos,
  }) {
    return EstadoHubCaptura(
      modo: modo ?? this.modo,
      duracionMaxima: duracionMaxima ?? this.duracionMaxima,
      grabando: grabando ?? this.grabando,
      procesando: procesando ?? this.procesando,
      transcurrido: transcurrido ?? this.transcurrido,
      capturaLista:
          limpiarCaptura ? null : (capturaLista ?? this.capturaLista),
      bloquearModos: bloquearModos ?? this.bloquearModos,
    );
  }

  static EstadoHubCaptura inicial() {
    return const EstadoHubCaptura(
      duracionMaxima: Duration(seconds: 15),
    );
  }
}
