import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/errores/fallo_app.dart';
import '../../autenticacion/aplicacion/proveedores_autenticacion.dart';
import '../../autenticacion/dominio/fallo_autenticacion.dart';
import '../../usuarios/aplicacion/proveedores_usuarios.dart';
import '../../usuarios/dominio/perfil_usuario.dart';

/// Perfil `usuarios/{uid}` en vivo del usuario con sesión.
final proveedorPerfilUsuarioActual =
    StreamProvider.autoDispose<PerfilUsuario?>((ref) {
  final uid = ref.watch(
    proveedorEstadoAutenticacion.select((estado) => estado.value?.uid),
  );
  if (uid == null) return Stream<PerfilUsuario?>.value(null);
  return ref.watch(proveedorRepositorioUsuarios).observarPerfil(uid);
});

/// Acciones del perfil: editar nombre, verificación de correo y cerrar
/// sesión.
class ControladorPerfil extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<bool> actualizarNombreVisible(String nombre) {
    final autenticacion = ref.read(proveedorRepositorioAutenticacion);
    final usuarios = ref.read(proveedorRepositorioUsuarios);
    final nombreLimpio = nombre.trim();
    return _ejecutar(() async {
      final usuario = autenticacion.usuarioActual;
      if (usuario == null) throw const FalloAutenticacion.desconocido();
      await usuarios.guardarNombreVisible(
        uid: usuario.uid,
        nombreVisible: nombreLimpio,
        correo: usuario.correo ?? '',
      );
      await autenticacion.actualizarNombreVisible(nombreLimpio);
    });
  }

  Future<bool> reenviarCorreoVerificacion() {
    final autenticacion = ref.read(proveedorRepositorioAutenticacion);
    return _ejecutar(autenticacion.enviarCorreoVerificacion);
  }

  /// Recarga el usuario para reflejar en la sesión un correo ya verificado.
  Future<bool> actualizarVerificacionCorreo() {
    final autenticacion = ref.read(proveedorRepositorioAutenticacion);
    return _ejecutar(() async {
      await autenticacion.recargarUsuario();
      if (ref.mounted) ref.invalidate(proveedorEstadoAutenticacion);
    });
  }

  Future<bool> cerrarSesion() {
    final autenticacion = ref.read(proveedorRepositorioAutenticacion);
    return _ejecutar(autenticacion.cerrarSesion);
  }

  Future<bool> _ejecutar(Future<void> Function() accion) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    try {
      await accion();
      if (ref.mounted) state = const AsyncData(null);
      return true;
    } on FalloApp catch (fallo, trazaPila) {
      if (ref.mounted) state = AsyncError(fallo, trazaPila);
      return false;
    } catch (error, trazaPila) {
      debugPrint('Capsoul: error no esperado en el perfil: $error');
      if (ref.mounted) {
        state = AsyncError(const FalloAutenticacion.desconocido(), trazaPila);
      }
      return false;
    }
  }
}

final proveedorControladorPerfil =
    NotifierProvider.autoDispose<ControladorPerfil, AsyncValue<void>>(
  ControladorPerfil.new,
);
