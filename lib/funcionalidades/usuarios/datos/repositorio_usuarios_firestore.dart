import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../dominio/fallo_perfil_usuario.dart';
import '../dominio/perfil_usuario.dart';
import '../dominio/repositorio_usuarios.dart';

/// [RepositorioUsuarios] respaldado por Cloud Firestore (`usuarios/{uid}`).
class RepositorioUsuariosFirestore implements RepositorioUsuarios {
  RepositorioUsuariosFirestore({FirebaseFirestore? firestore})
      : _firestoreInyectado = firestore;

  static const String rutaColeccion = 'usuarios';

  static const String campoNombreVisible = 'nombreVisible';
  static const String campoCorreo = 'correo';
  static const String campoFotoUrl = 'fotoUrl';
  static const String campoCreadoEn = 'creadoEn';

  final FirebaseFirestore? _firestoreInyectado;

  FirebaseFirestore get _firestore =>
      _firestoreInyectado ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _documento(String uid) =>
      _firestore.collection(rutaColeccion).doc(uid);

  @override
  Stream<PerfilUsuario?> observarPerfil(String uid) {
    return _documento(uid).snapshots().map(_desdeInstantanea).transform(
          StreamTransformer<PerfilUsuario?, PerfilUsuario?>.fromHandlers(
            handleError: (error, trazaPila, sumidero) =>
                sumidero.addError(_traducirError(error), trazaPila),
          ),
        );
  }

  @override
  Future<void> crearPerfil({
    required String uid,
    required String nombreVisible,
    required String correo,
  }) {
    return _proteger(
      () => _documento(uid).set({
        campoNombreVisible: nombreVisible,
        campoCorreo: correo,
        campoFotoUrl: null,
        campoCreadoEn: FieldValue.serverTimestamp(),
      }),
    );
  }

  @override
  Future<void> guardarNombreVisible({
    required String uid,
    required String nombreVisible,
    required String correo,
  }) {
    return _proteger(() async {
      final instantanea = await _documento(uid).get();
      if (instantanea.exists) {
        await _documento(uid).update({campoNombreVisible: nombreVisible});
      } else {
        await crearPerfil(
          uid: uid,
          nombreVisible: nombreVisible,
          correo: correo,
        );
      }
    });
  }

  /// Falla cerrado: los documentos mal formados se tratan como inexistentes.
  static PerfilUsuario? _desdeInstantanea(
    DocumentSnapshot<Map<String, dynamic>> instantanea,
  ) {
    final datos = instantanea.data();
    if (datos == null) return null;
    final nombreVisible = datos[campoNombreVisible];
    final correo = datos[campoCorreo];
    if (nombreVisible is! String || correo is! String) {
      debugPrint(
        'Capsoul: usuarios/${instantanea.id} tiene un formato inválido',
      );
      return null;
    }
    final fotoUrl = datos[campoFotoUrl];
    final creadoEn = datos[campoCreadoEn];
    return PerfilUsuario(
      uid: instantanea.id,
      nombreVisible: nombreVisible,
      correo: correo,
      fotoUrl: fotoUrl is String ? fotoUrl : null,
      creadoEn: creadoEn is Timestamp ? creadoEn.toDate() : null,
    );
  }

  static Future<T> _proteger<T>(Future<T> Function() accion) async {
    try {
      return await accion();
    } catch (error) {
      throw _traducirError(error);
    }
  }

  static Object _traducirError(Object error) {
    if (error is FalloPerfilUsuario) return error;
    if (error is FirebaseException) {
      return FalloPerfilUsuario.desdeCodigo(error.code);
    }
    debugPrint('Capsoul: error de perfil no esperado: $error');
    return FalloPerfilUsuario.desdeCodigo(FalloPerfilUsuario.codigoDesconocido);
  }
}
