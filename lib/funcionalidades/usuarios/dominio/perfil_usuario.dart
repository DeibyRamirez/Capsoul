/// Perfil guardado en Firestore en `usuarios/{uid}`.
class PerfilUsuario {
  const PerfilUsuario({
    required this.uid,
    required this.nombreVisible,
    required this.correo,
    this.fotoUrl,
    this.creadoEn,
  });

  final String uid;
  final String nombreVisible;
  final String correo;
  final String? fotoUrl;

  /// Es `null` mientras la marca de tiempo del servidor está pendiente.
  final DateTime? creadoEn;

  PerfilUsuario copiarCon({String? nombreVisible}) {
    return PerfilUsuario(
      uid: uid,
      nombreVisible: nombreVisible ?? this.nombreVisible,
      correo: correo,
      fotoUrl: fotoUrl,
      creadoEn: creadoEn,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PerfilUsuario &&
          other.uid == uid &&
          other.nombreVisible == nombreVisible &&
          other.correo == correo &&
          other.fotoUrl == fotoUrl &&
          other.creadoEn == creadoEn;

  @override
  int get hashCode => Object.hash(uid, nombreVisible, correo, fotoUrl, creadoEn);
}
