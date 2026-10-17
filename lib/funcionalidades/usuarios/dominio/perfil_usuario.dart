/// Perfil de la tabla `usuarios` de Supabase (1:1 con `auth.users`).
///
/// La fila la crea el trigger `auth_usuarios_1_crear_perfil` al registrarse.
class PerfilUsuario {
  const PerfilUsuario({
    required this.uid,
    required this.nombreVisible,
    required this.correo,
    this.nombreUsuario,
    this.fotoPublicId,
    this.perfilPublico = false,
    this.creadoEn,
  });

  final String uid;
  final String nombreVisible;
  final String correo;

  /// Identificador único `@cheiviz` (sin la arroba en la base).
  final String? nombreUsuario;

  bool get necesitaNombreUsuario =>
      nombreUsuario == null || nombreUsuario!.isEmpty;

  /// `public_id` del avatar en Cloudinary (`foto_public_id`), no una URL.
  final String? fotoPublicId;

  bool get tieneFoto =>
      fotoPublicId != null && fotoPublicId!.trim().isNotEmpty;

  /// Si otros usuarios que no son amigos pueden ver el perfil.
  final bool perfilPublico;

  final DateTime? creadoEn;

  PerfilUsuario copiarCon({
    String? nombreVisible,
    String? nombreUsuario,
    String? fotoPublicId,
  }) {
    return PerfilUsuario(
      uid: uid,
      nombreVisible: nombreVisible ?? this.nombreVisible,
      correo: correo,
      nombreUsuario: nombreUsuario ?? this.nombreUsuario,
      fotoPublicId: fotoPublicId ?? this.fotoPublicId,
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
          other.nombreUsuario == nombreUsuario &&
          other.fotoPublicId == fotoPublicId &&
          other.perfilPublico == perfilPublico &&
          other.creadoEn == creadoEn;

  @override
  int get hashCode => Object.hash(
        uid,
        nombreVisible,
        correo,
        nombreUsuario,
        fotoPublicId,
        perfilPublico,
        creadoEn,
      );
}
