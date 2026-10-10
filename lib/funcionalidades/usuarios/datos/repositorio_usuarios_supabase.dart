import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import '../../../nucleo/infraestructura/traductor_errores_backend.dart';

import '../dominio/fallo_perfil_usuario.dart';
import '../dominio/perfil_usuario.dart';
import '../dominio/repositorio_usuarios.dart';
import 'acceso_tabla_usuarios.dart';

/// [RepositorioUsuarios] respaldado por la tabla `usuarios` de Supabase.
///
/// No usa Realtime: lee la fila al suscribirse y vuelve a leerla cuando este
/// repositorio la modifica.
class RepositorioUsuariosSupabase implements RepositorioUsuarios {
  RepositorioUsuariosSupabase(this._acceso);

  static const String columnaId = 'id';
  static const String columnaNombreVisible = 'nombre_visible';
  static const String columnaCorreo = 'correo';
  static const String columnaFotoPublicId = 'foto_public_id';
  static const String columnaPerfilPublico = 'perfil_publico';
  static const String columnaCreadoEn = 'creado_en';

  final AccesoTablaUsuarios _acceso;
  final _cambios = StreamController<String>.broadcast();

  @override
  Stream<PerfilUsuario?> observarPerfil(String uid) async* {
    yield await _leerPerfil(uid);
    await for (final idCambiado in _cambios.stream) {
      if (idCambiado == uid) yield await _leerPerfil(uid);
    }
  }

  @override
  Future<void> guardarNombreVisible({
    required String uid,
    required String nombreVisible,
  }) async {
    final filas = await _proteger(
      () => _acceso.actualizarNombreVisible(uid, nombreVisible),
    );
    if (filas == 0) {
      throw FalloPerfilUsuario.desdeCodigo(
        FalloPerfilUsuario.codigoNoEncontrado,
      );
    }
    _cambios.add(uid);
  }

  /// Cierra el flujo interno de cambios (lo llama el proveedor).
  void liberarRecursos() => _cambios.close();

  Future<PerfilUsuario?> _leerPerfil(String uid) async {
    final fila = await _proteger(() => _acceso.leerFila(uid));
    return fila == null ? null : desdeFila(fila);
  }

  /// Falla cerrado: las filas mal formadas se tratan como inexistentes.
  @visibleForTesting
  static PerfilUsuario? desdeFila(Map<String, dynamic> fila) {
    final id = fila[columnaId];
    final nombreVisible = fila[columnaNombreVisible];
    final correo = fila[columnaCorreo];
    if (id is! String || nombreVisible is! String || correo is! String) {
      debugPrint('Capsoul: fila de usuarios con formato inválido');
      return null;
    }
    final fotoPublicId = fila[columnaFotoPublicId];
    final perfilPublico = fila[columnaPerfilPublico];
    final creadoEn = fila[columnaCreadoEn];
    return PerfilUsuario(
      uid: id,
      nombreVisible: nombreVisible,
      correo: correo,
      fotoPublicId: fotoPublicId is String ? fotoPublicId : null,
      perfilPublico: perfilPublico is bool && perfilPublico,
      creadoEn: creadoEn is String ? DateTime.tryParse(creadoEn) : null,
    );
  }

  static Future<T> _proteger<T>(Future<T> Function() accion) async {
    try {
      return await accion();
    } catch (error) {
      throw _traducirError(error);
    }
  }

  static FalloPerfilUsuario _traducirError(Object error) {
    if (error is FalloPerfilUsuario) return error;
    if (error is ErrorPostgrest) {
      final codigo = switch (error.codigo) {
        TraductorErroresBackend.permisoDenegado ||
        'PGRST301' ||
        'PGRST302' ||
        'PGRST303' =>
          FalloPerfilUsuario.codigoPermisoDenegado,
        '23514' => FalloPerfilUsuario.codigoDatoInvalido,
        _ => FalloPerfilUsuario.codigoDesconocido,
      };
      if (codigo == FalloPerfilUsuario.codigoDesconocido) {
        debugPrint('Capsoul: ErrorPostgrest no esperado: $error');
      }
      return FalloPerfilUsuario.desdeCodigo(codigo);
    }
    if (error is SocketException || error is TimeoutException) {
      return FalloPerfilUsuario.desdeCodigo(FalloPerfilUsuario.codigoSinRed);
    }
    debugPrint('Capsoul: error de perfil no esperado: $error');
    return FalloPerfilUsuario.desdeCodigo(FalloPerfilUsuario.codigoDesconocido);
  }
}
