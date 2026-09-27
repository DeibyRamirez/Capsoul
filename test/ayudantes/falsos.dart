import 'dart:async';

import 'package:capsoul/funcionalidades/autenticacion/dominio/fallo_autenticacion.dart';
import 'package:capsoul/funcionalidades/autenticacion/dominio/repositorio_autenticacion.dart';
import 'package:capsoul/funcionalidades/autenticacion/dominio/usuario_app.dart';
import 'package:capsoul/funcionalidades/usuarios/dominio/perfil_usuario.dart';
import 'package:capsoul/funcionalidades/usuarios/dominio/repositorio_usuarios.dart';

const usuarioPrueba = UsuarioApp(
  uid: 'uid-123',
  correo: 'ana@capsoul.app',
  nombreVisible: 'Ana',
  correoVerificado: true,
);

/// [RepositorioAutenticacion] en memoria para pruebas de widgets (sin
/// Firebase).
class RepositorioAutenticacionFalso implements RepositorioAutenticacion {
  RepositorioAutenticacionFalso({UsuarioApp? usuarioInicial})
      : _usuario = usuarioInicial;

  UsuarioApp? _usuario;
  final _cambios = StreamController<UsuarioApp?>.broadcast();

  /// Si se asigna, la siguiente llamada lanza este fallo.
  FalloAutenticacion? siguienteFallo;

  /// Si se asigna, el inicio de sesión espera a que se complete (para
  /// observar el estado de carga).
  Completer<void>? compuertaInicioSesion;

  String? ultimoCorreoRecuperacion;
  int correosVerificacionEnviados = 0;
  int llamadasCerrarSesion = 0;

  void _lanzarSiCorresponde() {
    final fallo = siguienteFallo;
    if (fallo != null) {
      siguienteFallo = null;
      throw fallo;
    }
  }

  void _asignarUsuario(UsuarioApp? usuario) {
    _usuario = usuario;
    _cambios.add(usuario);
  }

  @override
  Stream<UsuarioApp?> cambiosEstadoAutenticacion() async* {
    yield _usuario;
    yield* _cambios.stream;
  }

  @override
  UsuarioApp? get usuarioActual => _usuario;

  @override
  Future<UsuarioApp> iniciarSesion({
    required String correo,
    required String contrasena,
  }) async {
    final compuerta = compuertaInicioSesion;
    if (compuerta != null) await compuerta.future;
    _lanzarSiCorresponde();
    final usuario = UsuarioApp(
      uid: 'uid-123',
      correo: correo,
      correoVerificado: true,
    );
    _asignarUsuario(usuario);
    return usuario;
  }

  @override
  Future<UsuarioApp> registrarUsuario({
    required String nombre,
    required String correo,
    required String contrasena,
  }) async {
    _lanzarSiCorresponde();
    final usuario = UsuarioApp(
      uid: 'uid-nuevo',
      correo: correo,
      nombreVisible: nombre,
    );
    _asignarUsuario(usuario);
    return usuario;
  }

  @override
  Future<void> enviarCorreoRecuperacion(String correo) async {
    _lanzarSiCorresponde();
    ultimoCorreoRecuperacion = correo;
  }

  @override
  Future<void> enviarCorreoVerificacion() async {
    _lanzarSiCorresponde();
    correosVerificacionEnviados++;
  }

  @override
  Future<UsuarioApp?> recargarUsuario() async => _usuario;

  @override
  Future<void> actualizarNombreVisible(String nombre) async {
    _lanzarSiCorresponde();
    final usuario = _usuario;
    if (usuario == null) return;
    _usuario = UsuarioApp(
      uid: usuario.uid,
      correo: usuario.correo,
      nombreVisible: nombre,
      correoVerificado: usuario.correoVerificado,
    );
  }

  @override
  Future<void> cerrarSesion() async {
    llamadasCerrarSesion++;
    _asignarUsuario(null);
  }
}

/// [RepositorioUsuarios] en memoria para pruebas de widgets (sin Firestore).
class RepositorioUsuariosFalso implements RepositorioUsuarios {
  final Map<String, PerfilUsuario> perfiles = {};
  final _cambios = StreamController<void>.broadcast();

  @override
  Stream<PerfilUsuario?> observarPerfil(String uid) async* {
    yield perfiles[uid];
    await for (final _ in _cambios.stream) {
      yield perfiles[uid];
    }
  }

  @override
  Future<void> crearPerfil({
    required String uid,
    required String nombreVisible,
    required String correo,
  }) async {
    perfiles[uid] = PerfilUsuario(
      uid: uid,
      nombreVisible: nombreVisible,
      correo: correo,
    );
    _cambios.add(null);
  }

  @override
  Future<void> guardarNombreVisible({
    required String uid,
    required String nombreVisible,
    required String correo,
  }) async {
    final actual = perfiles[uid];
    perfiles[uid] = actual == null
        ? PerfilUsuario(uid: uid, nombreVisible: nombreVisible, correo: correo)
        : actual.copiarCon(nombreVisible: nombreVisible);
    _cambios.add(null);
  }
}
