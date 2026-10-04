import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../nucleo/supabase/configuracion_supabase.dart';
import '../dominio/fallo_autenticacion.dart';
import '../dominio/repositorio_autenticacion.dart';
import '../dominio/resultado_registro.dart';
import '../dominio/usuario_app.dart';

/// [RepositorioAutenticacion] respaldado por Supabase Auth.
///
/// [GoTrueClient] se puede inyectar en las pruebas; por defecto se resuelve
/// de forma diferida (`Supabase.instance.client.auth`) para que construir el
/// repositorio nunca toque la red.
///
/// Los enlaces de correo vuelven a la app por deep link
/// ([ConfiguracionSupabase.urlConfirmacion] y
/// [ConfiguracionSupabase.urlRecuperacion]); `supabase_flutter` los recibe con
/// `app_links` y abre la sesión.
class RepositorioAutenticacionSupabase implements RepositorioAutenticacion {
  RepositorioAutenticacionSupabase({
    GoTrueClient? auth,
    this.urlConfirmacion = ConfiguracionSupabase.urlConfirmacion,
    this.urlRecuperacion = ConfiguracionSupabase.urlRecuperacion,
  }) : _authInyectado = auth;

  /// Clave de `raw_user_meta_data` que lee el trigger de perfil.
  static const String claveNombreVisible = 'nombre_visible';

  final GoTrueClient? _authInyectado;
  final String urlConfirmacion;
  final String urlRecuperacion;

  GoTrueClient get _auth => _authInyectado ?? Supabase.instance.client.auth;

  @override
  Stream<UsuarioApp?> cambiosEstadoAutenticacion() =>
      _auth.onAuthStateChange.map((estado) => _aUsuarioApp(estado.session?.user));

  @override
  Stream<void> enlacesRecuperacion() => _auth.onAuthStateChange
      .where((estado) => estado.event == AuthChangeEvent.passwordRecovery)
      .map((_) {});

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
        emailRedirectTo: urlConfirmacion,
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
      () => _auth.resetPasswordForEmail(correo, redirectTo: urlRecuperacion),
    );
  }

  @override
  Future<void> reenviarCorreoConfirmacion(String correo) {
    return _proteger(() async {
      await _auth.resend(
        type: OtpType.signup,
        email: correo,
        emailRedirectTo: urlConfirmacion,
      );
    });
  }

  @override
  Future<void> actualizarContrasena(String contrasenaNueva) {
    return _proteger(() async {
      await _auth.updateUser(UserAttributes(password: contrasenaNueva));
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
