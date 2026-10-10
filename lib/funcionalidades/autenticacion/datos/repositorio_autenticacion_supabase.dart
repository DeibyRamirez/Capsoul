import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../nucleo/infraestructura/cliente_autenticacion.dart';
import '../../../nucleo/infraestructura/configuracion_backend.dart';
import '../dominio/fallo_autenticacion.dart';
import '../dominio/repositorio_autenticacion.dart';
import '../dominio/resultado_registro.dart';
import '../dominio/usuario_app.dart';

/// [RepositorioAutenticacion] que delega en [ClienteAutenticacion].
class RepositorioAutenticacionSupabase implements RepositorioAutenticacion {
  RepositorioAutenticacionSupabase(this._cliente);

  final ClienteAutenticacion _cliente;

  @override
  Stream<UsuarioApp?> cambiosEstadoAutenticacion() =>
      _cliente.cambiosEstado().map((estado) => estado.usuario);

  @override
  Stream<void> enlacesRecuperacion() => _cliente.cambiosEstado().where(
        (estado) => estado.evento == EventoAutenticacion.recuperacionContrasena,
      ).map((_) {});

  @override
  UsuarioApp? get usuarioActual => _cliente.usuarioActual;

  @override
  Future<UsuarioApp> iniciarSesion({
    required String correo,
    required String contrasena,
  }) {
    return _proteger(
      () => _cliente.iniciarSesion(correo: correo, contrasena: contrasena),
    );
  }

  @override
  Future<ResultadoRegistro> registrarUsuario({
    required String nombre,
    required String correo,
    required String contrasena,
  }) {
    return _proteger(
      () => _cliente.registrarUsuario(
        nombre: nombre,
        correo: correo,
        contrasena: contrasena,
        urlConfirmacion: ConfiguracionBackend.urlConfirmacion,
      ),
    );
  }

  @override
  Future<void> enviarCorreoRecuperacion(String correo) {
    return _proteger(
      () => _cliente.enviarCorreoRecuperacion(
        correo,
        urlRecuperacion: ConfiguracionBackend.urlRecuperacion,
      ),
    );
  }

  @override
  Future<void> reenviarCorreoConfirmacion(String correo) {
    return _proteger(
      () => _cliente.reenviarCorreoConfirmacion(
        correo,
        urlConfirmacion: ConfiguracionBackend.urlConfirmacion,
      ),
    );
  }

  @override
  Future<void> actualizarContrasena(String contrasenaNueva) {
    return _proteger(() => _cliente.actualizarContrasena(contrasenaNueva));
  }

  @override
  Future<void> actualizarNombreVisible(String nombre) {
    return _proteger(() => _cliente.actualizarNombreVisible(nombre));
  }

  @override
  Future<void> cerrarSesion() => _proteger(() => _cliente.cerrarSesion());

  static Future<T> _proteger<T>(Future<T> Function() accion) async {
    try {
      return await accion();
    } on FalloAutenticacion {
      rethrow;
    } on ExcepcionAutenticacion catch (error) {
      final codigo = error.codigo;
      if (codigo == '429') {
        throw FalloAutenticacion.desdeCodigo(
          FalloAutenticacion.codigoDemasiadosIntentos,
        );
      }
      throw FalloAutenticacion.desdeCodigo(
        codigo ?? FalloAutenticacion.codigoDesconocido,
      );
    } on TimeoutException {
      throw FalloAutenticacion.desdeCodigo(FalloAutenticacion.codigoSinRed);
    } catch (error) {
      debugPrint('Capsoul: error de autenticación no esperado: $error');
      throw const FalloAutenticacion.desconocido();
    }
  }
}
