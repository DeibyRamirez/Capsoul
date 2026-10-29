/// Recuerda el token FCM y lo vuelve a guardar cuando cambia la sesión.
///
/// El SDK avisa el token una vez. Si en ese momento no hay usuario,
/// el registro no persiste; al entrar una sesión hay que insistir con
/// el mismo token, sin volver a suscribirse a FCM.
class VinculoTokenPush {
  VinculoTokenPush({required this.registrar, required this.eliminar});

  final Future<void> Function(String token) registrar;
  final Future<void> Function(String token, String uid) eliminar;

  String? _token;

  String? get tokenRecordado => _token;

  /// Guarda el token en memoria y lo registra si ya hay sesión.
  Future<void> recordarToken(String token) async {
    if (token.isEmpty) return;
    _token = token;
    await registrar(token);
  }

  /// Insiste el registro al entrar un usuario y lo borra al salir.
  Future<void> alCambiarSesion({
    required String? uidAnterior,
    required String? uidNuevo,
  }) async {
    final token = _token;
    if (token == null) return;
    if (uidNuevo != null && uidNuevo != uidAnterior) {
      await registrar(token);
      return;
    }
    if (uidAnterior != null && uidNuevo == null) {
      await eliminar(token, uidAnterior);
    }
  }
}
