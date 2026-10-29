import '../../../nucleo/formato/fechas.dart';
import 'estado_capsula.dart';

/// Cómo se lee el estado en la tarjeta.
///
/// `abierta` no está en `estado_capsula`: es `liberada` con `abierta_en`.
/// La fecha vencida no convierte una `programada` en lista para abrir.
enum EstadoVisibleCapsula {
  borrador('Borrador'),
  programada('Programada'),
  listaParaAbrir('Lista para abrir'),
  abierta('Abierta'),
  cancelada('Cancelada');

  const EstadoVisibleCapsula(this.etiqueta);

  final String etiqueta;
}

/// Estado que ve quien mira la tarjeta. [abierta] solo cuenta si ya está liberada.
EstadoVisibleCapsula estadoVisibleCapsula({
  required EstadoCapsula estado,
  required bool abierta,
}) {
  return switch (estado) {
    EstadoCapsula.borrador => EstadoVisibleCapsula.borrador,
    EstadoCapsula.programada => EstadoVisibleCapsula.programada,
    EstadoCapsula.cancelada => EstadoVisibleCapsula.cancelada,
    EstadoCapsula.liberada => abierta
        ? EstadoVisibleCapsula.abierta
        : EstadoVisibleCapsula.listaParaAbrir,
  };
}

/// Textos de la tarjeta para un estado real.
class PresentacionEstadoCapsula {
  const PresentacionEstadoCapsula({
    required this.visible,
    required this.detalle,
    required this.aviso,
  });

  final EstadoVisibleCapsula visible;

  /// Fecha y hora si aplica, o «Sin fecha» en un borrador.
  final String? detalle;

  /// Aviso cuando la fecha ya pasó y el cron todavía no la liberó.
  final String? aviso;

  bool get conCandado =>
      visible != EstadoVisibleCapsula.listaParaAbrir &&
      visible != EstadoVisibleCapsula.abierta;

  bool get brilla => !conCandado;
}

PresentacionEstadoCapsula presentarEstadoCapsula({
  required EstadoCapsula estado,
  required bool abierta,
  required DateTime? fechaApertura,
  required DateTime ahora,
}) {
  final visible = estadoVisibleCapsula(estado: estado, abierta: abierta);
  final esperaLiberacion = visible == EstadoVisibleCapsula.programada &&
      fechaApertura != null &&
      !fechaApertura.isAfter(ahora);
  final String? detalle = switch (visible) {
    EstadoVisibleCapsula.programada when fechaApertura != null =>
      formatearFechaHora(fechaApertura),
    EstadoVisibleCapsula.borrador when fechaApertura != null =>
      formatearFechaHora(fechaApertura),
    EstadoVisibleCapsula.borrador => 'Sin fecha',
    _ => null,
  };
  return PresentacionEstadoCapsula(
    visible: visible,
    detalle: detalle,
    aviso: esperaLiberacion ? 'Aún no liberada' : null,
  );
}
