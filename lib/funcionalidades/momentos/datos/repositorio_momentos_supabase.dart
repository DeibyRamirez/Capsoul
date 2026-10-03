import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../nucleo/errores/fallo_app.dart';
import '../../../nucleo/identificadores/generador_ids.dart';
import '../../../nucleo/supabase/errores_postgrest.dart';
import '../../recuerdos/datos/mapeo_recuerdos.dart';
import '../../recuerdos/dominio/recuerdo.dart';
import '../dominio/fallo_momento.dart';
import '../dominio/momento.dart';
import '../dominio/nuevo_momento.dart';
import '../dominio/repositorio_momentos.dart';
import '../dominio/validador_momento.dart';
import 'acceso_tablas_momentos.dart';

/// [RepositorioMomentos] con Supabase (migraciones 000001 y 000004).
///
/// Orden al crear: insertar el momento (id del cliente, visibilidad
/// `privado`) → unir los recuerdos en `momento_elementos` → fijar la portada
/// (el trigger exige que ya esté unida). Si algo falla se borra el momento.
class RepositorioMomentosSupabase implements RepositorioMomentos {
  RepositorioMomentosSupabase({
    required this._acceso,
    required this._uidActual,
    GeneradorIds? generarId,
  }) : _generarId = generarId ?? generarIdAleatorio;

  /// SQLSTATE del trigger de portada (migración 000004).
  static const String codigoPortadaInvalida = 'CAP04';

  final AccesoTablasMomentos _acceso;
  final String? Function() _uidActual;
  final GeneradorIds _generarId;

  String _uid() => _uidActual() ?? (throw const FalloMomento.sinSesion());

  @override
  Future<String> crear(NuevoMomento nuevo) async {
    final uid = _uid();
    final fallo = ValidadorMomento.validar(nuevo);
    if (fallo != null) throw fallo;
    final id = _generarId();
    var insertado = false;
    try {
      final descripcion = nuevo.descripcion?.trim();
      await _acceso.insertarMomento({
        'id': id,
        'autor_id': uid,
        'titulo': nuevo.titulo.trim(),
        'texto': (descripcion == null || descripcion.isEmpty)
            ? null
            : descripcion,
        // Decisión: por ahora todos los momentos son privados.
        'visibilidad': 'privado',
      });
      insertado = true;
      await _acceso.insertarEnlaces([
        for (var i = 0; i < nuevo.recuerdos.length; i++)
          {'momento_id': id, 'elemento_id': nuevo.recuerdos[i].id, 'orden': i},
      ]);
      final portada = nuevo.portadaId;
      if (portada != null) await _acceso.actualizarPortada(id, portada);
      return id;
    } catch (error) {
      if (insertado) {
        try {
          await _acceso.eliminarMomento(id);
        } catch (e) {
          debugPrint('Capsoul: no se pudo deshacer el momento incompleto: $e');
        }
      }
      throw traducirError(error);
    }
  }

  @override
  Future<List<Momento>> listar() async {
    final uid = _uid();
    try {
      final filas = await _acceso.listarDeAutor(uid);
      return [for (final fila in filas) ?momentoDesdeFila(fila)];
    } catch (error) {
      throw traducirError(error);
    }
  }

  @override
  Future<Momento?> obtener(String id) async {
    _uid();
    try {
      final fila = await _acceso.leerConRecuerdos(id);
      return fila == null ? null : momentoDesdeFila(fila);
    } catch (error) {
      throw traducirError(error);
    }
  }

  @override
  Future<void> eliminar(String id) async {
    _uid();
    int borradas;
    try {
      borradas = await _acceso.eliminarMomento(id);
    } catch (error) {
      throw traducirError(error);
    }
    if (borradas == 0) throw const FalloMomento.permisoDenegado();
  }

  /// Falla cerrado: sin id, autor, título o fecha válidos se descarta.
  @visibleForTesting
  static Momento? momentoDesdeFila(Map<String, dynamic> fila) {
    final id = fila['id'];
    final autor = fila['autor_id'];
    final titulo = fila['titulo'];
    final creado = fila['creado_en'];
    final creadoEn = creado is String ? DateTime.tryParse(creado) : null;
    if (id is! String || autor is! String || titulo is! String ||
        creadoEn == null) {
      return null;
    }
    final texto = fila['texto'];
    final enlaces = fila['momento_elementos'];
    final ordenados = <(int, Recuerdo)>[];
    var cantidad = 0;
    if (enlaces is List) {
      for (final enlace in enlaces) {
        if (enlace is! Map) continue;
        final conteo = enlace['count'];
        if (conteo is num) {
          cantidad = conteo.toInt();
          continue;
        }
        final recuerdo = recuerdoDesdeFila(enlace['elementos']);
        if (recuerdo == null) continue;
        final orden = enlace['orden'];
        ordenados.add((orden is num ? orden.toInt() : 0, recuerdo));
      }
    }
    ordenados.sort((a, b) => a.$1.compareTo(b.$1));
    final recuerdos = [for (final (_, r) in ordenados) r];
    return Momento(
      id: id,
      autorId: autor,
      titulo: titulo,
      descripcion: texto is String ? texto : null,
      creadoEn: creadoEn,
      portada: recuerdoDesdeFila(fila['portada']),
      cantidad: recuerdos.isEmpty ? cantidad : recuerdos.length,
      recuerdos: List.unmodifiable(recuerdos),
    );
  }

  @visibleForTesting
  static FalloApp traducirError(Object error) {
    if (error is FalloApp) return error;
    if (error is PostgrestException) {
      switch (error.code) {
        case codigoPortadaInvalida:
          return const FalloMomento.portadaInvalida();
        case ErroresPostgrest.permisoDenegado:
          return const FalloMomento.permisoDenegado();
        case '23514':
          return const FalloMomento.tituloInvalido();
        case final codigo? when ErroresPostgrest.sesionInvalida.contains(codigo):
          return const FalloMomento.sesionVencida();
      }
      debugPrint('Capsoul: PostgrestException no esperada: $error');
      return const FalloMomento.desconocido();
    }
    if (error is SocketException || error is TimeoutException) {
      return const FalloMomento.sinRed();
    }
    debugPrint('Capsoul: error de momentos no esperado: $error');
    return const FalloMomento.desconocido();
  }
}
