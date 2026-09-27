import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../usuarios/aplicacion/proveedores_usuarios.dart';
import '../dominio/fallo_autenticacion.dart';
import 'proveedores_autenticacion.dart';

/// Base de las acciones de autenticación de un solo disparo con estado
/// inactivo / cargando / error.
///
/// [ejecutar] devuelve `true` cuando la acción terminó bien.
abstract class ControladorAccionAutenticacion
    extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  @protected
  Future<bool> ejecutar(Future<void> Function() accion) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    try {
      await accion();
      if (ref.mounted) state = const AsyncData(null);
      return true;
    } on FalloAutenticacion catch (fallo, trazaPila) {
      if (ref.mounted) state = AsyncError(fallo, trazaPila);
      return false;
    } catch (error, trazaPila) {
      debugPrint('Capsoul: error no esperado en autenticación: $error');
      if (ref.mounted) {
        state = AsyncError(const FalloAutenticacion.desconocido(), trazaPila);
      }
      return false;
    }
  }
}

class ControladorInicioSesion extends ControladorAccionAutenticacion {
  Future<bool> iniciarSesion({
    required String correo,
    required String contrasena,
  }) {
    final repositorio = ref.read(proveedorRepositorioAutenticacion);
    return ejecutar(
      () => repositorio.iniciarSesion(
        correo: correo.trim(),
        contrasena: contrasena,
      ),
    );
  }
}

class ControladorRegistro extends ControladorAccionAutenticacion {
  /// Crea la cuenta, el documento `usuarios/{uid}` y envía el correo de
  /// verificación. Los errores del perfil y del correo no bloquean la
  /// entrada.
  Future<bool> registrarUsuario({
    required String nombre,
    required String correo,
    required String contrasena,
  }) {
    final autenticacion = ref.read(proveedorRepositorioAutenticacion);
    final usuarios = ref.read(proveedorRepositorioUsuarios);
    final nombreLimpio = nombre.trim();
    final correoLimpio = correo.trim();

    return ejecutar(() async {
      final usuario = await autenticacion.registrarUsuario(
        nombre: nombreLimpio,
        correo: correoLimpio,
        contrasena: contrasena,
      );
      try {
        await usuarios.crearPerfil(
          uid: usuario.uid,
          nombreVisible: nombreLimpio,
          correo: usuario.correo ?? correoLimpio,
        );
      } catch (error) {
        debugPrint('Capsoul: no se pudo crear usuarios/${usuario.uid}: $error');
      }
      try {
        await autenticacion.enviarCorreoVerificacion();
      } catch (error) {
        debugPrint('Capsoul: no se pudo enviar la verificación: $error');
      }
    });
  }
}

class ControladorRecuperacionContrasena extends ControladorAccionAutenticacion {
  /// Envía el enlace de recuperación. `user-not-found` se trata como éxito
  /// para que la interfaz nunca revele si la cuenta existe.
  Future<bool> enviarEnlaceRecuperacion(String correo) {
    final repositorio = ref.read(proveedorRepositorioAutenticacion);
    return ejecutar(() async {
      try {
        await repositorio.enviarCorreoRecuperacion(correo.trim());
      } on FalloAutenticacion catch (fallo) {
        if (!fallo.esUsuarioNoEncontrado) rethrow;
      }
    });
  }
}

final proveedorControladorInicioSesion =
    NotifierProvider.autoDispose<ControladorInicioSesion, AsyncValue<void>>(
  ControladorInicioSesion.new,
);

final proveedorControladorRegistro =
    NotifierProvider.autoDispose<ControladorRegistro, AsyncValue<void>>(
  ControladorRegistro.new,
);

final proveedorControladorRecuperacion = NotifierProvider.autoDispose<
    ControladorRecuperacionContrasena, AsyncValue<void>>(
  ControladorRecuperacionContrasena.new,
);
