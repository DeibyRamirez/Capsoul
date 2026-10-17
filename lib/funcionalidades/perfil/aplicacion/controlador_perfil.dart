import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/errores/fallo_app.dart';
import '../../../nucleo/firebase/escucha_tokens_push.dart';
import '../../autenticacion/aplicacion/proveedores_autenticacion.dart';
import '../../autenticacion/dominio/fallo_autenticacion.dart';
import '../../elementos/aplicacion/proveedores_elementos.dart';
import '../../elementos/dominio/tipo_elemento.dart';
import '../../usuarios/aplicacion/proveedores_usuarios.dart';
import '../../usuarios/dominio/perfil_usuario.dart';
import 'proveedor_avatar_perfil.dart';

/// Perfil (tabla `usuarios`) del usuario con sesión.
final proveedorPerfilUsuarioActual =
    StreamProvider.autoDispose<PerfilUsuario?>((ref) {
  final uid = ref.watch(
    proveedorEstadoAutenticacion.select((estado) => estado.value?.uid),
  );
  if (uid == null) return Stream<PerfilUsuario?>.value(null);
  return ref.watch(proveedorRepositorioUsuarios).observarPerfil(uid);
});

/// Acciones del perfil: editar nombre y cerrar sesión. (Todo usuario con
/// sesión ya confirmó su correo: Supabase Auth lo exige.)
class ControladorPerfil extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<bool> subirFotoPerfil(String rutaLocal) {
    final autenticacion = ref.read(proveedorRepositorioAutenticacion);
    final medios = ref.read(proveedorRepositorioMedios);
    final usuarios = ref.read(proveedorRepositorioUsuarios);
    final compresor = ref.read(proveedorCompresorMedios);
    return _ejecutar(() async {
      final usuario = autenticacion.usuarioActual;
      if (usuario == null) throw const FalloAutenticacion.desconocido();
      final preparada = await compresor.prepararFoto(rutaLocal);
      if (preparada.tipo != TipoElemento.foto) {
        throw const FalloAutenticacion.desconocido();
      }
      final subido = await medios.subirAvatarPerfil(preparada);
      await usuarios.guardarFotoPerfil(
        uid: usuario.uid,
        fotoPublicId: subido.publicId,
      );
      ref.invalidate(proveedorUrlsAvatarPerfil);
      ref.invalidate(proveedorUrlAvatarPerfil);
      ref.invalidate(proveedorPerfilUsuarioActual);
    });
  }

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
      );
      await autenticacion.actualizarNombreVisible(nombreLimpio);
    });
  }

  Future<bool> cerrarSesion() {
    final autenticacion = ref.read(proveedorRepositorioAutenticacion);
    final dispositivos = ref.read(proveedorRepositorioDispositivosPush);
    return _ejecutar(() async {
      try {
        await dispositivos.eliminarTodosLosTokensDelUsuario();
      } catch (_) {
        // Si falla la red, igual cerramos la sesión local.
      }
      await autenticacion.cerrarSesion();
    });
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
