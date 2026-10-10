import 'dart:async';

import 'package:capsoul/funcionalidades/autenticacion/dominio/fallo_autenticacion.dart';
import 'package:capsoul/funcionalidades/autenticacion/dominio/repositorio_autenticacion.dart';
import 'package:capsoul/funcionalidades/autenticacion/dominio/resultado_registro.dart';
import 'package:capsoul/funcionalidades/autenticacion/dominio/usuario_app.dart';
import 'package:capsoul/funcionalidades/usuarios/dominio/fallo_perfil_usuario.dart';
import 'package:capsoul/funcionalidades/usuarios/dominio/perfil_usuario.dart';
import 'package:capsoul/funcionalidades/elementos/dominio/medio_subido.dart';
import 'package:capsoul/funcionalidades/elementos/dominio/tipo_elemento.dart';
import 'package:capsoul/funcionalidades/recuerdos/dominio/url_medio.dart';
import 'package:capsoul/funcionalidades/usuarios/dominio/repositorio_usuarios.dart';
import 'package:capsoul/nucleo/infraestructura/cliente_almacenamiento.dart';
import 'package:capsoul/nucleo/infraestructura/cliente_autenticacion.dart';
import 'package:capsoul/nucleo/infraestructura/cliente_funciones_api.dart';
import 'package:capsoul/nucleo/infraestructura/cliente_postgrest.dart';
import 'package:capsoul/nucleo/infraestructura/consulta_postgrest.dart';

const usuarioPrueba = UsuarioApp(
  uid: 'uid-123',
  correo: 'ana@capsoul.app',
  nombreVisible: 'Ana',
  correoVerificado: true,
);

/// [RepositorioAutenticacion] en memoria para pruebas de widgets (sin
/// Supabase).
class RepositorioAutenticacionFalso implements RepositorioAutenticacion {
  RepositorioAutenticacionFalso({
    UsuarioApp? usuarioInicial,
    this.exigeConfirmarCorreo = false,
  }) : _usuario = usuarioInicial;

  /// Simula un proyecto de Supabase que exige confirmar el correo: el
  /// registro no abre sesión.
  final bool exigeConfirmarCorreo;

  UsuarioApp? _usuario;
  final _cambios = StreamController<UsuarioApp?>.broadcast();
  final _recuperaciones = StreamController<void>.broadcast();

  /// Si se asigna, la siguiente llamada lanza este fallo.
  FalloAutenticacion? siguienteFallo;

  /// Si se asigna, el inicio de sesión espera a que se complete (para
  /// observar el estado de carga).
  Completer<void>? compuertaInicioSesion;

  /// Igual que [compuertaInicioSesion], para el reenvío de confirmación.
  Completer<void>? compuertaReenvio;

  String? ultimoCorreoRecuperacion;
  String? ultimoNombreRegistrado;
  final List<String> correosConfirmacionReenviados = [];
  String? ultimaContrasenaNueva;
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
  Future<ResultadoRegistro> registrarUsuario({
    required String nombre,
    required String correo,
    required String contrasena,
  }) async {
    _lanzarSiCorresponde();
    ultimoNombreRegistrado = nombre;
    final usuario = UsuarioApp(
      uid: 'uid-nuevo',
      correo: correo,
      nombreVisible: nombre,
      correoVerificado: !exigeConfirmarCorreo,
    );
    if (!exigeConfirmarCorreo) _asignarUsuario(usuario);
    return ResultadoRegistro(
      usuario: usuario,
      sesionIniciada: !exigeConfirmarCorreo,
    );
  }

  @override
  Future<void> enviarCorreoRecuperacion(String correo) async {
    _lanzarSiCorresponde();
    ultimoCorreoRecuperacion = correo;
  }

  @override
  Future<void> reenviarCorreoConfirmacion(String correo) async {
    final compuerta = compuertaReenvio;
    if (compuerta != null) await compuerta.future;
    _lanzarSiCorresponde();
    correosConfirmacionReenviados.add(correo);
  }

  @override
  Stream<void> enlacesRecuperacion() => _recuperaciones.stream;

  /// Simula abrir el enlace de recuperación: sesión temporal + evento
  /// `passwordRecovery`.
  void simularEnlaceRecuperacion({UsuarioApp usuario = usuarioPrueba}) {
    _asignarUsuario(usuario);
    _recuperaciones.add(null);
  }

  @override
  Future<void> actualizarContrasena(String contrasenaNueva) async {
    _lanzarSiCorresponde();
    ultimaContrasenaNueva = contrasenaNueva;
  }

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

/// [RepositorioUsuarios] en memoria para pruebas de widgets (sin Supabase).
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
  Future<void> guardarNombreVisible({
    required String uid,
    required String nombreVisible,
  }) async {
    final actual = perfiles[uid];
    if (actual == null) {
      throw FalloPerfilUsuario.desdeCodigo(
        FalloPerfilUsuario.codigoNoEncontrado,
      );
    }
    perfiles[uid] = actual.copiarCon(nombreVisible: nombreVisible);
    _cambios.add(null);
  }
}

/// [ClientePostgrest] en memoria para pruebas unitarias.
class ClientePostgrestFalso implements ClientePostgrest {
  final Map<String, List<Map<String, dynamic>>> tablas = {};
  final Map<String, List<dynamic>> rpcs = {};

  @override
  TablaPostgrest from(String tabla) => TablaPostgrestFalsa(tabla, this);

  @override
  Future<List<dynamic>> rpc(
    String nombre, {
    Map<String, dynamic>? parametros,
  }) async =>
      rpcs[nombre] ?? const [];
}

class TablaPostgrestFalsa implements TablaPostgrest {
  TablaPostgrestFalsa(this.nombre, this.cliente);

  final String nombre;
  final ClientePostgrestFalso cliente;

  @override
  Future<void> insertar(Map<String, dynamic> fila) async {
    cliente.tablas.putIfAbsent(nombre, () => []).add(fila);
  }

  @override
  Future<void> insertarMuchos(List<Map<String, dynamic>> filas) async {
    cliente.tablas.putIfAbsent(nombre, () => []).addAll(filas);
  }

  @override
  SeleccionPostgrest seleccionar([String columnas = '*']) =>
      SeleccionPostgrestFalsa(cliente.tablas[nombre] ?? const []);

  @override
  ActualizacionPostgrest actualizar(Map<String, dynamic> valores) =>
      ActualizacionPostgrestFalsa(valores, cliente.tablas[nombre] ??= []);

  @override
  EliminacionPostgrest eliminar() =>
      EliminacionPostgrestFalsa(cliente.tablas[nombre] ??= []);
}

class SeleccionPostgrestFalsa implements SeleccionPostgrest {
  SeleccionPostgrestFalsa(this._filas);

  List<Map<String, dynamic>> _filas;

  @override
  SeleccionPostgrest eq(String columna, Object valor) {
    _filas = _filas.where((f) => f[columna] == valor).toList();
    return this;
  }

  @override
  SeleccionPostgrest neq(String columna, Object valor) {
    _filas = _filas.where((f) => f[columna] != valor).toList();
    return this;
  }

  @override
  SeleccionPostgrest gte(String columna, Object valor) =>
      this;

  @override
  SeleccionPostgrest lte(String columna, Object valor) =>
      this;

  @override
  SeleccionPostgrest inFilter(String columna, List<Object> valores) {
    _filas = _filas.where((f) => valores.contains(f[columna])).toList();
    return this;
  }

  @override
  SeleccionPostgrest order(String columna, {bool ascendente = true}) =>
      this;

  @override
  SeleccionPostgrest limit(int cantidad) {
    _filas = _filas.take(cantidad).toList();
    return this;
  }

  @override
  Future<List<Map<String, dynamic>>> ejecutar() async => _filas;

  @override
  Future<Map<String, dynamic>?> maybeSingle() async =>
      _filas.isEmpty ? null : _filas.first;

  @override
  Future<ConteoPostgrest> contar() async => ConteoPostgrest(_filas.length);
}

class ActualizacionPostgrestFalsa implements ActualizacionPostgrest {
  ActualizacionPostgrestFalsa(this._valores, this._filas);

  final Map<String, dynamic> _valores;
  final List<Map<String, dynamic>> _filas;

  @override
  ActualizacionPostgrest eq(String columna, Object valor) => this;

  @override
  Future<List<Map<String, dynamic>>> select(String columnas) async {
    for (final fila in _filas) {
      fila.addAll(_valores);
    }
    return _filas;
  }

  @override
  Future<void> ejecutar() async {}
}

class EliminacionPostgrestFalsa implements EliminacionPostgrest {
  EliminacionPostgrestFalsa(this._filas);

  final List<Map<String, dynamic>> _filas;

  @override
  EliminacionPostgrest eq(String columna, Object valor) => this;

  @override
  Future<List<Map<String, dynamic>>> select(String columnas) async {
    final borradas = List<Map<String, dynamic>>.from(_filas);
    _filas.clear();
    return borradas;
  }

  @override
  Future<void> ejecutar() async => _filas.clear();
}

/// [ClienteFuncionesApi] en memoria para pruebas.
class ClienteFuncionesApiFalso implements ClienteFuncionesApi {
  FirmaSubida? firma;
  List<UrlMedio> medios = const [];

  @override
  Future<FirmaSubida> firmarSubida({
    required TipoElemento tipo,
    required int bytes,
    Duration? duracion,
    String? formato,
  }) async =>
      firma ??
      const FirmaSubida(
        urlSubida: 'https://api.cloudinary.com/v1_1/nube/image/upload',
        parametros: {
          'api_key': '1',
          'timestamp': '1',
          'signature': 's',
          'public_id': 'p',
        },
      );

  @override
  Future<List<UrlMedio>> firmarMedio(List<String> idsElemento) async => medios;

  List<Map<String, dynamic>> resultadosMusica = const [];

  @override
  Future<List<Map<String, dynamic>>> buscarMusica({
    required String consulta,
    int limite = 10,
    String mercado = 'CO',
  }) async =>
      resultadosMusica;
}

/// [ClienteAlmacenamiento] en memoria para pruebas.
class ClienteAlmacenamientoFalso implements ClienteAlmacenamiento {
  MedioSubido? resultado;

  @override
  Future<MedioSubido> subirArchivo({
    required String rutaLocal,
    required String urlSubida,
    required Map<String, String> parametrosFirma,
  }) async =>
      resultado ??
      const MedioSubido(
        publicId: 'capsoul/prueba',
        tipoRecurso: 'image',
        bytes: 1,
      );
}

/// [ClienteAutenticacion] en memoria para pruebas de infraestructura.
class ClienteAutenticacionFalso implements ClienteAutenticacion {
  ClienteAutenticacionFalso({UsuarioApp? usuario}) : _usuario = usuario;

  UsuarioApp? _usuario;
  String? _token;
  final _cambios = StreamController<SesionAutenticacion>.broadcast();

  @override
  Stream<SesionAutenticacion> cambiosEstado() async* {
    yield SesionAutenticacion(
      usuario: _usuario,
      evento: _usuario == null
          ? EventoAutenticacion.cerrada
          : EventoAutenticacion.iniciada,
    );
    yield* _cambios.stream;
  }

  @override
  UsuarioApp? get usuarioActual => _usuario;

  @override
  String? get tokenAcceso => _token;

  @override
  Future<UsuarioApp> iniciarSesion({
    required String correo,
    required String contrasena,
  }) async {
    _usuario = UsuarioApp(uid: 'uid-falso', correo: correo);
    _token = 'token-falso';
    return _usuario!;
  }

  @override
  Future<ResultadoRegistro> registrarUsuario({
    required String nombre,
    required String correo,
    required String contrasena,
    required String urlConfirmacion,
  }) async {
    _usuario = UsuarioApp(
      uid: 'uid-nuevo',
      correo: correo,
      nombreVisible: nombre,
    );
    return ResultadoRegistro(usuario: _usuario!, sesionIniciada: true);
  }

  @override
  Future<void> enviarCorreoRecuperacion(
    String correo, {
    required String urlRecuperacion,
  }) async {}

  @override
  Future<void> reenviarCorreoConfirmacion(
    String correo, {
    required String urlConfirmacion,
  }) async {}

  @override
  Future<void> actualizarContrasena(String contrasenaNueva) async {}

  @override
  Future<void> actualizarNombreVisible(String nombre) async {}

  @override
  Future<void> cerrarSesion() async {
    _usuario = null;
    _token = null;
  }
}
