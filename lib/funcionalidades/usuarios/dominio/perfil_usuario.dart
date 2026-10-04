/// Perfil de la tabla `usuarios` de Supabase (1:1 con `auth.users`).
///
/// La fila la crea el trigger `auth_usuarios_1_crear_perfil` al registrarse.
class PerfilUsuario {
  const PerfilUsuario({
    required this.uid,
    required this.nombreVisible,
    required this.correo,
    this.fotoPublicId,
    this.perfilPublico = false,
    this.creadoEn,
  });

  final String uid;
  final String nombreVisible;
  final String correo;

  /// `public_id` del avatar en Cloudinary (`foto_public_id`), no una URL.
  final String? fotoPublicId;

  /// Si otros usuarios que no son amigos pueden ver el perfil.
  final bool perfilPublico;

  final DateTime? creadoEn;

  PerfilUsuario copiarCon({String? nombreVisible}) {
    return PerfilUsuario(
      uid: uid,
      nombreVisible: nombreVisible ?? this.nombreVisible,
      correo: correo,
      fotoPublicId: fotoPublicId,
      perfilPublico: perfilPublico,
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
          other.fotoPublicId == fotoPublicId &&
          other.perfilPublico == perfilPublico &&
          other.creadoEn == creadoEn;

  @override
  int get hashCode => Object.hash(
        uid,
        nombreVisible,
        correo,
        fotoPublicId,
        perfilPublico,
        creadoEn,
      );
}
