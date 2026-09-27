import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../dominio/fallo_autenticacion.dart';
import '../dominio/repositorio_autenticacion.dart';
import '../dominio/usuario_app.dart';

/// [RepositorioAutenticacion] respaldado por Firebase Authentication.
///
/// [FirebaseAuth] se puede inyectar en las pruebas; por defecto la instancia
/// se resuelve de forma diferida para que construir el repositorio nunca
/// toque Firebase.
class RepositorioAutenticacionFirebase implements RepositorioAutenticacion {
  RepositorioAutenticacionFirebase({FirebaseAuth? auth}) : _authInyectado = auth;

  final FirebaseAuth? _authInyectado;

  FirebaseAuth get _auth => _authInyectado ?? FirebaseAuth.instance;

  @override
  Stream<UsuarioApp?> cambiosEstadoAutenticacion() =>
      _auth.authStateChanges().map(_aUsuarioApp);

  @override
  UsuarioApp? get usuarioActual => _aUsuarioApp(_auth.currentUser);

  @override
  Future<UsuarioApp> iniciarSesion({
    required String correo,
    required String contrasena,
  }) {
    return _proteger(() async {
      final credencial = await _auth.signInWithEmailAndPassword(
        email: correo,
        password: contrasena,
      );
      return _exigirUsuario(credencial.user);
    });
  }

  @override
  Future<UsuarioApp> registrarUsuario({
    required String nombre,
    required String correo,
    required String contrasena,
  }) {
    return _proteger(() async {
      final credencial = await _auth.createUserWithEmailAndPassword(
        email: correo,
        password: contrasena,
      );
      final usuario = credencial.user;
      if (usuario == null) throw const FalloAutenticacion.desconocido();
      await usuario.updateDisplayName(nombre);
      return UsuarioApp(
        uid: usuario.uid,
        correo: usuario.email ?? correo,
        nombreVisible: nombre,
        correoVerificado: usuario.emailVerified,
      );
    });
  }

  @override
  Future<void> enviarCorreoRecuperacion(String correo) {
    return _proteger(() => _auth.sendPasswordResetEmail(email: correo));
  }

  @override
  Future<void> enviarCorreoVerificacion() {
    return _proteger(() async {
      final usuario = _auth.currentUser;
      if (usuario == null) throw const FalloAutenticacion.desconocido();
      await usuario.sendEmailVerification();
    });
  }

  @override
  Future<UsuarioApp?> recargarUsuario() {
    return _proteger(() async {
      await _auth.currentUser?.reload();
      return _aUsuarioApp(_auth.currentUser);
    });
  }

  @override
  Future<void> actualizarNombreVisible(String nombre) {
    return _proteger(() async {
      final usuario = _auth.currentUser;
      if (usuario == null) throw const FalloAutenticacion.desconocido();
      await usuario.updateDisplayName(nombre);
    });
  }

  @override
  Future<void> cerrarSesion() => _proteger(_auth.signOut);

  UsuarioApp _exigirUsuario(User? usuario) {
    final usuarioApp = _aUsuarioApp(usuario);
    if (usuarioApp == null) throw const FalloAutenticacion.desconocido();
    return usuarioApp;
  }

  static UsuarioApp? _aUsuarioApp(User? usuario) {
    if (usuario == null) return null;
    return UsuarioApp(
      uid: usuario.uid,
      correo: usuario.email,
      nombreVisible: usuario.displayName,
      correoVerificado: usuario.emailVerified,
    );
  }

  /// Traduce cualquier error a [FalloAutenticacion].
  static Future<T> _proteger<T>(Future<T> Function() accion) async {
    try {
      return await accion();
    } on FirebaseAuthException catch (error) {
      throw FalloAutenticacion.desdeCodigo(error.code);
    } on FalloAutenticacion {
      rethrow;
    } catch (error) {
      debugPrint('Capsoul: error de autenticación no esperado: $error');
      throw const FalloAutenticacion.desconocido();
    }
  }
}
