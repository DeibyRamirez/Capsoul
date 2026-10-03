import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../dominio/fallo_autenticacion.dart';
import '../dominio/repositorio_autenticacion.dart';
import '../dominio/resultado_registro.dart';
import '../dominio/usuario_app.dart';

/// [RepositorioAutenticacion] respaldado por Supabase Auth.
///
/// [GoTrueClient] se puede inyectar en las pruebas; por defecto se resuelve
/// de forma diferida (`Supabase.instance.client.auth`) para que construir el
/// repositorio nunca toque la red.
class RepositorioAutenticacionSupabase implements RepositorioAutenticacion {
  RepositorioAutenticacionSupabase({GoTrueClient? auth, String? urlRedireccion})
      : _authInyectado = auth,
        _urlRedireccion =
            (urlRedireccion == null || urlRedireccion.isEmpty) ? null : urlRedireccion;

  /// Clave de `raw_user_meta_data` que lee el trigger de perfil.
  static const String claveNombreVisible = 'nombre_visible';

  final GoTrueClient? _authInyectado;
  final String? _urlRedireccion;

  GoTrueClient get _auth => _authInyectado ?? Supabase.instance.client.auth;

  @override
  Stream<UsuarioApp?> cambiosEstadoAutenticacion() =>
      _auth.onAuthStateChange.map((estado) => _aUsuarioApp(estado.session?.user));

  @override
  UsuarioApp? get usuarioActual => _aUsuarioApp(_auth.currentUser);

  @override
  Future<UsuarioApp> iniciarSesion({
    required String correo,
    required String contrasena,
  }) {
    return _proteger(() async {
      final respuesta = await _auth.signInWithPassword(
        email: correo,
        password: contrasena,
      );
      final usuario = _aUsuarioApp(respuesta.user);
      if (usuario == null) throw const FalloAutenticacion.desconocido();
      return usuario;
    });
  }

  @override
  Future<ResultadoRegistro> registrarUsuario({
    required String nombre,
    required String correo,
    required String contrasena,
  }) {
    return _proteger(() async {
      final respuesta = await _auth.signUp(
        email: correo,
        password: contrasena,
        data: {claveNombreVisible: nombre},
        emailRedirectTo: _urlRedireccion,
      );
      final usuario = respuesta.user;
      if (usuario == null) throw const FalloAutenticacion.desconocido();
      return ResultadoRegistro(
        usuario: UsuarioApp(
          uid: usuario.id,
          correo: usuario.email ?? correo,
          nombreVisible: nombre,
          correoVerificado: usuario.emailConfirmedAt != null,
        ),
        sesionIniciada: respuesta.session != null,
      );
    });
  }

  @override
  Future<void> enviarCorreoRecuperacion(String correo) {
    return _proteger(
      () => _auth.resetPasswordForEmail(correo, redirectTo: _urlRedireccion),
    );
  }

  @override
  Future<void> enviarCorreoVerificacion() {
    return _proteger(() async {
      final correo = _auth.currentUser?.email;
      if (correo == null) throw const FalloAutenticacion.desconocido();
      await _auth.resend(
        type: OtpType.signup,
        email: correo,
        emailRedirectTo: _urlRedireccion,
      );
    });
  }

  @override
  Future<UsuarioApp?> recargarUsuario() {
    return _proteger(() async {
      if (_auth.currentSession == null) return null;
      final respuesta = await _auth.refreshSession();
      return _aUsuarioApp(respuesta.user ?? _auth.currentUser);
    });
  }

  @override
  Future<void> actualizarNombreVisible(String nombre) {
    return _proteger(() async {
      await _auth.updateUser(UserAttributes(data: {claveNombreVisible: nombre}));
    });
  }

  @override
  Future<void> cerrarSesion() => _proteger(() => _auth.signOut());

  static UsuarioApp? _aUsuarioApp(User? usuario) {
    if (usuario == null) return null;
    final nombre = usuario.userMetadata?[claveNombreVisible];
    return UsuarioApp(
      uid: usuario.id,
      correo: usuario.email,
      nombreVisible: nombre is String ? nombre : null,
      correoVerificado: usuario.emailConfirmedAt != null,
    );
  }

  /// Traduce cualquier error a [FalloAutenticacion].
  static Future<T> _proteger<T>(Future<T> Function() accion) async {
    try {
      return await accion();
    } on FalloAutenticacion {
      rethrow;
    } on AuthRetryableFetchException {
      throw FalloAutenticacion.desdeCodigo(FalloAutenticacion.codigoSinRed);
    } on AuthException catch (error) {
      throw FalloAutenticacion.desdeCodigo(_codigoDe(error));
    } on SocketException {
      throw FalloAutenticacion.desdeCodigo(FalloAutenticacion.codigoSinRed);
    } on TimeoutException {
      throw FalloAutenticacion.desdeCodigo(FalloAutenticacion.codigoSinRed);
    } catch (error) {
      debugPrint('Capsoul: error de autenticación no esperado: $error');
      throw const FalloAutenticacion.desconocido();
    }
  }

  static String _codigoDe(AuthException error) {
    final codigo = error.code;
    if (codigo != null && codigo.isNotEmpty) return codigo;
    if (error.statusCode == '429') {
      return FalloAutenticacion.codigoDemasiadosIntentos;
    }
    debugPrint('Capsoul: AuthException sin código: $error');
    return FalloAutenticacion.codigoDesconocido;
  }
}
