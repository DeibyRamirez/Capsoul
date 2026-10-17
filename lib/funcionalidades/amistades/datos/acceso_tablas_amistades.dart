import '../../../nucleo/infraestructura/cliente_postgrest.dart';

abstract interface class AccesoTablasAmistades {
  Future<List<Map<String, dynamic>>> leerAmigosRpc();

  Future<List<Map<String, dynamic>>> leerSolicitudesRpc();

  Future<void> actualizarEstadoAmistad(String id, String estado);

  Future<String> crearInvitacionRpc();

  Future<void> aceptarInvitacionRpc(String token);

  Future<List<Map<String, dynamic>>> resolverUsuarioPorArrobaRpc(String arroba);

  Future<void> enviarSolicitudAmistadRpc(String receptorId);
}

class AccesoTablasAmistadesPostgrest implements AccesoTablasAmistades {
  AccesoTablasAmistadesPostgrest(this._cliente);

  final ClientePostgrest _cliente;

  @override
  Future<List<Map<String, dynamic>>> leerAmigosRpc() async {
    final filas = await _cliente.rpc('mis_amigos');
    return [
      for (final fila in filas)
        if (fila is Map<String, dynamic>) fila,
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> leerSolicitudesRpc() async {
    final filas = await _cliente.rpc('mis_solicitudes_amistad_pendientes');
    return [
      for (final fila in filas)
        if (fila is Map<String, dynamic>) fila,
    ];
  }

  @override
  Future<void> actualizarEstadoAmistad(String id, String estado) async {
    await _cliente
        .from('amistades')
        .actualizar({'estado': estado})
        .eq('id', id)
        .ejecutar();
  }

  @override
  Future<String> crearInvitacionRpc() async {
    final filas = await _cliente.rpc('crear_invitacion_amistad');
    if (filas.isEmpty) {
      throw StateError('crear_invitacion_amistad sin token');
    }
    final primera = filas.first;
    if (primera is String && primera.isNotEmpty) return primera;
    if (primera is Map && primera.containsKey('crear_invitacion_amistad')) {
      final tok = primera['crear_invitacion_amistad'];
      if (tok is String && tok.isNotEmpty) return tok;
    }
    throw StateError('crear_invitacion_amistad sin token');
  }

  @override
  Future<void> aceptarInvitacionRpc(String token) async {
    await _cliente.rpc('aceptar_invitacion_amistad', parametros: {'p_token': token});
  }

  @override
  Future<List<Map<String, dynamic>>> resolverUsuarioPorArrobaRpc(
    String arroba,
  ) async {
    final filas = await _cliente.rpc(
      'resolver_usuario_por_arroba',
      parametros: {'p_arroba': arroba},
    );
    return [
      for (final fila in filas)
        if (fila is Map<String, dynamic>) fila,
    ];
  }

  @override
  Future<void> enviarSolicitudAmistadRpc(String receptorId) async {
    await _cliente.rpc(
      'enviar_solicitud_amistad',
      parametros: {'p_receptor_id': receptorId},
    );
  }
}
