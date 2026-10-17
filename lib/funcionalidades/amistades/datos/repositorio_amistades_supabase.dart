import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../nucleo/errores/fallo_app.dart';
import '../../../nucleo/infraestructura/traductor_errores_backend.dart';
import '../dominio/amigo.dart';
import '../dominio/fallo_amistad.dart';
import '../dominio/repositorio_amistades.dart';
import '../dominio/usuario_resuelto.dart';
import '../../../nucleo/dominio/validador_nombre_usuario.dart';
import 'acceso_tablas_amistades.dart';

class RepositorioAmistadesSupabase implements RepositorioAmistades {
  RepositorioAmistadesSupabase({
    required this._acceso,
    required this._uidActual,
  });

  final AccesoTablasAmistades _acceso;
  final String? Function() _uidActual;

  void _exigirSesion() {
    if (_uidActual() == null) throw const FalloAmistad.sinSesion();
  }

  @override
  Future<List<Amigo>> listarAmigos() async {
    _exigirSesion();
    try {
      final filas = await _acceso.leerAmigosRpc();
      return [for (final fila in filas) ?Amigo.desdeFilaRpc(fila)];
    } catch (error) {
      throw _traducir(error);
    }
  }

  @override
  Future<List<SolicitudAmistad>> listarSolicitudesPendientes() async {
    _exigirSesion();
    try {
      final filas = await _acceso.leerSolicitudesRpc();
      return [
        for (final fila in filas) ?SolicitudAmistad.desdeFilaRpc(fila),
      ];
    } catch (error) {
      throw _traducir(error);
    }
  }

  @override
  Future<void> aceptarSolicitud(String amistadId) async {
    _exigirSesion();
    try {
      await _acceso.actualizarEstadoAmistad(amistadId, 'aceptada');
    } catch (error) {
      throw _traducir(error);
    }
  }

  @override
  Future<void> rechazarSolicitud(String amistadId) async {
    _exigirSesion();
    try {
      await _acceso.actualizarEstadoAmistad(amistadId, 'rechazada');
    } catch (error) {
      throw _traducir(error);
    }
  }

  @override
  Future<UsuarioResuelto?> resolverPorArroba(String arroba) async {
    _exigirSesion();
    final normalizado = ValidadorNombreUsuario.normalizar(arroba);
    if (ValidadorNombreUsuario.validar(normalizado) != null) {
      return null;
    }
    try {
      final filas = await _acceso.resolverUsuarioPorArrobaRpc(normalizado);
      if (filas.isEmpty) return null;
      return UsuarioResuelto.desdeFilaRpc(filas.first);
    } catch (error) {
      throw _traducir(error);
    }
  }

  @override
  Future<void> enviarSolicitudAmistad(String receptorUsuarioId) async {
    _exigirSesion();
    try {
      await _acceso.enviarSolicitudAmistadRpc(receptorUsuarioId);
    } catch (error) {
      throw _traducir(error);
    }
  }

  @override
  Future<String> crearInvitacionEnlace() async {
    _exigirSesion();
    try {
      return await _acceso.crearInvitacionRpc();
    } catch (error) {
      throw _traducir(error);
    }
  }

  @override
  Future<void> aceptarInvitacion(String token) async {
    _exigirSesion();
    try {
      await _acceso.aceptarInvitacionRpc(token.trim());
    } catch (error) {
      throw _traducir(error);
    }
  }

  FalloApp _traducir(Object error) {
    if (error is FalloApp) return error;
    final mensaje = error.toString();
    if (mensaje.contains('invitacion_invalida')) {
      return const FalloAmistad.invitacionInvalida();
    }
    if (mensaje.contains('usuario_no_existe')) {
      return const FalloAmistad.usuarioNoEncontrado();
    }
    if (mensaje.contains('ya_son_amigos')) {
      return const FalloAmistad.yaSonAmigos();
    }
    if (mensaje.contains('solicitud_pendiente')) {
      return const FalloAmistad.solicitudPendiente();
    }
    if (mensaje.contains('receptor_invalido')) {
      return const FalloAmistad.receptorInvalido();
    }
    return RepositorioAmistadesSupabase.traducirError(error);
  }

  @visibleForTesting
  static FalloApp traducirError(Object error) {
    if (error is FalloApp) return error;
    if (error is ErrorPostgrest) {
      switch (error.codigo) {
        case TraductorErroresBackend.permisoDenegado:
          return const FalloAmistad.permisoDenegado();
        case final codigo?
            when TraductorErroresBackend.sesionInvalida.contains(codigo):
          return const FalloAmistad.sinSesion();
        case 'P0001' when error.mensaje.contains('invitacion_invalida'):
          return const FalloAmistad.invitacionInvalida();
        case 'P0001' when error.mensaje.contains('sin_sesion'):
          return const FalloAmistad.sinSesion();
        case 'P0001' when error.mensaje.contains('usuario_no_existe'):
          return const FalloAmistad.usuarioNoEncontrado();
        case 'P0001' when error.mensaje.contains('ya_son_amigos'):
          return const FalloAmistad.yaSonAmigos();
        case 'P0001' when error.mensaje.contains('solicitud_pendiente'):
          return const FalloAmistad.solicitudPendiente();
        case 'P0001' when error.mensaje.contains('receptor_invalido'):
          return const FalloAmistad.receptorInvalido();
      }
      debugPrint('Capsoul: ErrorPostgrest amistades: $error');
      return const FalloAmistad.desconocido();
    }
    if (error is SocketException || error is TimeoutException) {
      return const FalloAmistad.desconocido();
    }
    debugPrint('Capsoul: error de amistades no esperado: $error');
    return const FalloAmistad.desconocido();
  }
}
