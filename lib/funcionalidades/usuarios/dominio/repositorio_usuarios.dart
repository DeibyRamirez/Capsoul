import 'perfil_usuario.dart';

/// Acceso a la fila propia de la tabla `usuarios`. Las implementaciones
/// lanzan [FalloPerfilUsuario] cuando algo sale mal.
///
/// La fila no se crea desde el cliente: la crea el trigger del servidor al
/// registrarse en Supabase Auth.
abstract interface class RepositorioUsuarios {
  /// Emite el perfil al suscribirse y cada vez que este repositorio lo
  /// modifica; `null` si la fila no existe o está mal formada.
  Stream<PerfilUsuario?> observarPerfil(String uid);

  /// Actualiza `nombre_visible` de la fila propia.
  Future<void> guardarNombreVisible({
    required String uid,
    required String nombreVisible,
  });
}
