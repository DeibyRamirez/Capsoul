import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dominio/fallo_autenticacion.dart';
import '../dominio/resultado_registro.dart';
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

/// Resultado de la acción de registro para que la pantalla decida a dónde ir.
enum ResultadoAccionRegistro {
  /// Falló; el error queda en el estado del controlador.
  fallido,

  /// Hay sesión: el enrutador lleva al contenedor principal.
  sesionIniciada,

  /// Supabase exige confirmar el correo antes de iniciar sesión.
  confirmacionPendiente,
}

class ControladorRegistro extends ControladorAccionAutenticacion {
  /// Crea la cuenta en Supabase Auth con el nombre visible en los metadatos.
  /// La fila `usuarios` la crea el trigger del servidor y Supabase envía el
  /// correo de confirmación por su cuenta.
  Future<ResultadoAccionRegistro> registrarUsuario({
    required String nombre,
    required String correo,
    required String contrasena,
  }) async {
    final autenticacion = ref.read(proveedorRepositorioAutenticacion);
    ResultadoRegistro? resultado;
    final exito = await ejecutar(() async {
      resultado = await autenticacion.registrarUsuario(
        nombre: nombre.trim(),
        correo: correo.trim(),
        contrasena: contrasena,
      );
    });
    final registro = resultado;
    if (!exito || registro == null) return ResultadoAccionRegistro.fallido;
    return registro.sesionIniciada
        ? ResultadoAccionRegistro.sesionIniciada
        : ResultadoAccionRegistro.confirmacionPendiente;
  }
}

class ControladorRecuperacionContrasena extends ControladorAccionAutenticacion {
  /// Envía el enlace de recuperación. `user_not_found` se trata como éxito
  /// para que la interfaz nunca revele si la cuenta existe (Supabase ya
  /// responde igual exista o no la cuenta).
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
