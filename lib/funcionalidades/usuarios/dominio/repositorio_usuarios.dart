import 'perfil_usuario.dart';

/// Acceso al documento `usuarios/{uid}`. Las implementaciones lanzan
/// [FalloPerfilUsuario] cuando algo sale mal.
abstract interface class RepositorioUsuarios {
  /// Perfil en vivo; emite `null` si el documento no existe o está mal
  /// formado.
  Stream<PerfilUsuario?> observarPerfil(String uid);

  /// Crea `usuarios/{uid}` justo después del registro.
  Future<void> crearPerfil({
    required String uid,
    required String nombreVisible,
    required String correo,
  });

  /// Actualiza el nombre visible y crea el documento si falta.
  Future<void> guardarNombreVisible({
    required String uid,
    required String nombreVisible,
    required String correo,
  });
}
