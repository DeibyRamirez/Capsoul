import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../../funcionalidades/autenticacion/dominio/resultado_registro.dart';
import '../../../../funcionalidades/autenticacion/dominio/usuario_app.dart';
import '../../cliente_autenticacion.dart';
import '../../configuracion_backend.dart';

/// [ClienteAutenticacion] para VPS que obtiene JWT desde la API Capsoul.
///
/// Stub funcional: las rutas coinciden con `api/openapi.yaml`.
class ClienteAutenticacionJwt implements ClienteAutenticacion {
  ClienteAutenticacionJwt({
    http.Client? clienteHttp,
    String? urlBase,
  })  : _http = clienteHttp ?? http.Client(),
        _urlBase = (urlBase ?? ConfiguracionBackend.apiBaseUrl).trim();

  final http.Client _http;
  final String _urlBase;
  UsuarioApp? _usuarioActual;
  String? _tokenAcceso;
  final _cambios = StreamController<SesionAutenticacion>.broadcast();

  Uri _uri(String ruta) {
    final base = _urlBase.endsWith('/') ? _urlBase : '$_urlBase/';
    return Uri.parse('$base$ruta');
  }

  @override
  Stream<SesionAutenticacion> cambiosEstado() async* {
    yield SesionAutenticacion(
      usuario: _usuarioActual,
      evento: _usuarioActual == null
          ? EventoAutenticacion.cerrada
          : EventoAutenticacion.iniciada,
    );
    yield* _cambios.stream;
  }

  @override
  UsuarioApp? get usuarioActual => _usuarioActual;

  @override
  String? get tokenAcceso => _tokenAcceso;

  @override
  Future<UsuarioApp> iniciarSesion({
    required String correo,
    required String contrasena,
  }) async {
    final respuesta = await _http.post(
      _uri('v1/auth/iniciar-sesion'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'correo': correo, 'contrasena': contrasena}),
    );
    _verificar(respuesta);
    final datos = jsonDecode(respuesta.body) as Map<String, dynamic>;
    _tokenAcceso = datos['token'] as String?;
    final usuario = _usuarioDesdeJson(datos['usuario']);
    _usuarioActual = usuario;
    _cambios.add(
      SesionAutenticacion(usuario: usuario, evento: EventoAutenticacion.iniciada),
    );
    return usuario;
  }

  @override
  Future<ResultadoRegistro> registrarUsuario({
    required String nombre,
    required String correo,
    required String contrasena,
    required String urlConfirmacion,
  }) async {
    final respuesta = await _http.post(
      _uri('v1/auth/registro'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': nombre,
        'correo': correo,
        'contrasena': contrasena,
        'url_confirmacion': urlConfirmacion,
      }),
    );
    _verificar(respuesta);
    final datos = jsonDecode(respuesta.body) as Map<String, dynamic>;
    final usuario = _usuarioDesdeJson(datos['usuario']);
    final sesionIniciada = datos['sesion_iniciada'] == true;
    if (sesionIniciada) {
      _tokenAcceso = datos['token'] as String?;
      _usuarioActual = usuario;
      _cambios.add(
        SesionAutenticacion(
          usuario: usuario,
          evento: EventoAutenticacion.iniciada,
        ),
      );
    }
    return ResultadoRegistro(usuario: usuario, sesionIniciada: sesionIniciada);
  }

  @override
  Future<void> enviarCorreoRecuperacion(
    String correo, {
    required String urlRecuperacion,
  }) async {
    final respuesta = await _http.post(
      _uri('v1/auth/recuperar'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'correo': correo,
        'url_recuperacion': urlRecuperacion,
      }),
    );
    _verificar(respuesta);
  }

  @override
  Future<void> reenviarCorreoConfirmacion(
    String correo, {
    required String urlConfirmacion,
  }) async {
    final respuesta = await _http.post(
      _uri('v1/auth/reenviar-confirmacion'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'correo': correo,
        'url_confirmacion': urlConfirmacion,
      }),
    );
    _verificar(respuesta);
  }

  @override
  Future<void> actualizarContrasena(String contrasenaNueva) async {
    final respuesta = await _http.post(
      _uri('v1/auth/actualizar-contrasena'),
      headers: {
        'Content-Type': 'application/json',
        if (_tokenAcceso != null) 'Authorization': 'Bearer $_tokenAcceso',
      },
      body: jsonEncode({'contrasena_nueva': contrasenaNueva}),
    );
    _verificar(respuesta);
  }

  @override
  Future<void> actualizarNombreVisible(String nombre) async {
    final respuesta = await _http.post(
      _uri('v1/auth/actualizar-nombre'),
      headers: {
        'Content-Type': 'application/json',
        if (_tokenAcceso != null) 'Authorization': 'Bearer $_tokenAcceso',
      },
      body: jsonEncode({'nombre_visible': nombre}),
    );
    _verificar(respuesta);
    final usuario = _usuarioActual;
    if (usuario != null) {
      _usuarioActual = UsuarioApp(
        uid: usuario.uid,
        correo: usuario.correo,
        nombreVisible: nombre,
        correoVerificado: usuario.correoVerificado,
      );
      _cambios.add(
        SesionAutenticacion(
          usuario: _usuarioActual,
          evento: EventoAutenticacion.actualizada,
        ),
      );
    }
  }

  @override
  Future<void> cerrarSesion() async {
    _usuarioActual = null;
    _tokenAcceso = null;
    _cambios.add(
      const SesionAutenticacion(
        usuario: null,
        evento: EventoAutenticacion.cerrada,
      ),
    );
  }

  void liberarRecursos() {
    _cambios.close();
    _http.close();
  }

  static UsuarioApp _usuarioDesdeJson(Object? datos) {
    if (datos is! Map) {
      throw const FormatException('Usuario inválido');
    }
    return UsuarioApp(
      uid: datos['uid'] as String,
      correo: datos['correo'] as String?,
      nombreVisible: datos['nombre_visible'] as String?,
      correoVerificado: datos['correo_verificado'] == true,
    );
  }

  static void _verificar(http.Response respuesta) {
    if (respuesta.statusCode >= 200 && respuesta.statusCode < 300) return;
    throw HttpException(
      'Auth API ${respuesta.statusCode}: ${respuesta.body}',
      uri: respuesta.request?.url,
    );
  }
}
