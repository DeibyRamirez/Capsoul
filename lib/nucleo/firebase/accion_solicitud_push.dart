import '../enlaces/enlace_capsoul.dart';
import 'aviso_push.dart';

/// Aceptar o rechazar desde un botón del aviso.
class AccionSolicitudPush {
  const AccionSolicitudPush({required this.amistadId, required this.aceptar});

  final String amistadId;
  final bool aceptar;
}

/// Botón que la bandeja de Android muestra en el aviso.
class AccionBandejaAviso {
  const AccionBandejaAviso({required this.etiqueta, required this.ruta});

  final String etiqueta;
  final String ruta;
}

final _idAmistad = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

/// `capsoul://amigos?accion=aceptar&amistad_id=<uuid>`.
String rutaAccionSolicitud({required String amistadId, required bool aceptar}) {
  final accion = aceptar ? 'aceptar' : 'rechazar';
  return '${EnlaceCapsoul.amigos()}?accion=$accion'
      '&amistad_id=${Uri.encodeQueryComponent(amistadId)}';
}

/// Lee la acción del deep link. Si el id no es un uuid, no hay acción.
AccionSolicitudPush? accionSolicitudDesdeRuta(String ruta) {
  final uri = Uri.tryParse(ruta);
  if (uri == null || !EnlaceCapsoul.esAmigos(uri)) return null;
  final id = uri.queryParameters['amistad_id'];
  if (id == null || !_idAmistad.hasMatch(id)) return null;
  return switch (uri.queryParameters['accion']) {
    'aceptar' => AccionSolicitudPush(amistadId: id, aceptar: true),
    'rechazar' => AccionSolicitudPush(amistadId: id, aceptar: false),
    _ => null,
  };
}

/// Aceptar y Rechazar solo en un aviso de solicitud con id de amistad.
List<AccionBandejaAviso> accionesBandejaDe(MensajePush mensaje) {
  if (mensaje.tipo != tipoAvisoSolicitudAmistad) return const [];
  final id = mensaje.datos['amistad_id'];
  if (id == null || !_idAmistad.hasMatch(id)) return const [];
  final aceptar = mensaje.datos['accion_aceptar'];
  final rechazar = mensaje.datos['accion_rechazar'];
  return [
    AccionBandejaAviso(
      etiqueta: 'Rechazar',
      ruta: rechazar != null && rechazar.isNotEmpty
          ? rechazar
          : rutaAccionSolicitud(amistadId: id, aceptar: false),
    ),
    AccionBandejaAviso(
      etiqueta: 'Aceptar',
      ruta: aceptar != null && aceptar.isNotEmpty
          ? aceptar
          : rutaAccionSolicitud(amistadId: id, aceptar: true),
    ),
  ];
}

/// Argumentos del canal `capsoul/avisos` para [PresentadorAvisosAndroid].
Map<String, Object?> argumentosMostrarAviso(MensajePush mensaje) {
  return {
    'titulo': mensaje.titulo ?? 'Capsoul',
    'cuerpo': mensaje.cuerpo ?? '',
    if (mensaje.ruta != null) 'ruta': mensaje.ruta,
    'acciones': [
      for (final accion in accionesBandejaDe(mensaje))
        {'etiqueta': accion.etiqueta, 'ruta': accion.ruta},
    ],
  };
}
