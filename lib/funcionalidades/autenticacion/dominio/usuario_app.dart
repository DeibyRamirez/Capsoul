/// Usuario autenticado tal como lo ve la app (desacoplado de los tipos de
/// Firebase).
class UsuarioApp {
  const UsuarioApp({
    required this.uid,
    this.correo,
    this.nombreVisible,
    this.correoVerificado = false,
  });

  final String uid;
  final String? correo;
  final String? nombreVisible;
  final bool correoVerificado;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UsuarioApp &&
          other.uid == uid &&
          other.correo == correo &&
          other.nombreVisible == nombreVisible &&
          other.correoVerificado == correoVerificado;

  @override
  int get hashCode => Object.hash(uid, correo, nombreVisible, correoVerificado);

  @override
  String toString() => 'UsuarioApp(uid: $uid, correo: $correo)';
}
