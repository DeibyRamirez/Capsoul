import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../funcionalidades/autenticacion/dominio/resultado_registro.dart';
import '../../../../funcionalidades/autenticacion/dominio/usuario_app.dart';
import '../../cliente_autenticacion.dart';

/// [ClienteAutenticacion] respaldado por Supabase Auth (GoTrue).
class ClienteAutenticacionSupabase implements ClienteAutenticacion {
  ClienteAutenticacionSupabase({GoTrueClient? auth}) : _authInyectado = auth;

  static const String claveNombreVisible = 'nombre_visible';

  final GoTrueClient? _authInyectado;

  GoTrueClient get _auth => _authInyectado ?? Supabase.instance.client.auth;

  @override
  Stream<SesionAutenticacion> cambiosEstado() => _auth.onAuthStateChange.map(
        (estado) => SesionAutenticacion(
          usuario: _aUsuarioApp(estado.session?.user),
          evento: _eventoDe(estado.event),
        ),
      );

  @override
  UsuarioApp? get usuarioActual => _aUsuarioApp(_auth.currentUser);

  @override
  String? get tokenAcceso => _auth.currentSession?.accessToken;

  @override
  Future<UsuarioApp> iniciarSesion({
    required String correo,
    required String contrasena,
  }) =>
      _proteger(() async {
        final respuesta = await _auth.signInWithPassword(
          email: correo,
          password: contrasena,
        );
        final usuario = _aUsuarioApp(respuesta.user);
        if (usuario == null) {
          throw const ExcepcionAutenticacion(
            codigo: 'desconocido',
            mensaje: 'Usuario nulo tras iniciar sesión',
          );
        }
        return usuario;
      });

  @override
  Future<ResultadoRegistro> registrarUsuario({
    required String nombre,
    required String correo,
    required String contrasena,
    required String urlConfirmacion,
  }) =>
      _proteger(() async {
        final respuesta = await _auth.signUp(
          email: correo,
          password: contrasena,
          data: {claveNombreVisible: nombre},
          emailRedirectTo: urlConfirmacion,
        );
        final usuario = respuesta.user;
        if (usuario == null) {
          throw const ExcepcionAutenticacion(
            codigo: 'desconocido',
            mensaje: 'Usuario nulo tras registro',
          );
        }
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

  @override
  Future<void> enviarCorreoRecuperacion(
    String correo, {
    required String urlRecuperacion,
  }) =>
      _proteger(
        () => _auth.resetPasswordForEmail(correo, redirectTo: urlRecuperacion),
      );

  @override
  Future<void> reenviarCorreoConfirmacion(
    String correo, {
    required String urlConfirmacion,
  }) =>
      _proteger(
        () => _auth.resend(
          type: OtpType.signup,
          email: correo,
          emailRedirectTo: urlConfirmacion,
        ),
      );

  @override
  Future<void> actualizarContrasena(String contrasenaNueva) =>
      _proteger(() => _auth.updateUser(UserAttributes(password: contrasenaNueva)));

  @override
  Future<void> actualizarNombreVisible(String nombre) => _proteger(
        () => _auth.updateUser(UserAttributes(data: {claveNombreVisible: nombre})),
      );

  @override
  Future<void> cerrarSesion() => _proteger(() => _auth.signOut());

  static Future<T> _proteger<T>(Future<T> Function() accion) async {
    try {
      return await accion();
    } on ExcepcionAutenticacion {
      rethrow;
    } on AuthRetryableFetchException {
      throw const ExcepcionAutenticacion(
        codigo: 'sin_red',
        mensaje: 'Sin conexión',
      );
    } on AuthException catch (error) {
      throw ExcepcionAutenticacion(
        codigo: error.code ?? error.statusCode,
        mensaje: error.message,
      );
    } on TimeoutException {
      throw const ExcepcionAutenticacion(
        codigo: 'sin_red',
        mensaje: 'Sin conexión',
      );
    }
  }

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

  static EventoAutenticacion _eventoDe(AuthChangeEvent evento) =>
      switch (evento) {
        AuthChangeEvent.signedIn => EventoAutenticacion.iniciada,
        AuthChangeEvent.signedOut => EventoAutenticacion.cerrada,
        AuthChangeEvent.passwordRecovery =>
          EventoAutenticacion.recuperacionContrasena,
        AuthChangeEvent.userUpdated => EventoAutenticacion.actualizada,
        _ => EventoAutenticacion.desconocido,
      };
}
