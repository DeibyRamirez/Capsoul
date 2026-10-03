import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../nucleo/errores/fallo_app.dart';
import '../../../nucleo/identificadores/generador_ids.dart';
import '../../../nucleo/supabase/errores_postgrest.dart';
import '../../elementos/dominio/elemento_borrador.dart';
import '../../elementos/dominio/fallo_medios.dart';
import '../../elementos/dominio/repositorio_medios.dart';
import '../../elementos/dominio/tipo_elemento.dart';
import '../dominio/fallo_recuerdo.dart';
import '../dominio/filtro_recuerdos.dart';
import '../dominio/nuevo_recuerdo.dart';
import '../dominio/recuerdo.dart';
import '../dominio/repositorio_recuerdos.dart';
import '../dominio/uso_medios.dart';
import '../dominio/validador_recuerdo.dart';
import 'acceso_tablas_recuerdos.dart';
import 'mapeo_recuerdos.dart';

/// [RepositorioRecuerdos] con Supabase (`elementos`, migraciones 000001,
/// 000003 y 000004) y medios en Cloudinary vía [RepositorioMedios].
class RepositorioRecuerdosSupabase implements RepositorioRecuerdos {
  RepositorioRecuerdosSupabase({
    required this._acceso,
    required this._medios,
    required this._uidActual,
    DateTime Function()? reloj,
    GeneradorIds? generarId,
  })  : _reloj = reloj ?? DateTime.now,
        _generarId = generarId ?? generarIdAleatorio;

  /// SQLSTATE propios (migraciones 000003 y 000004).
  static const String codigoCuotaExcedida = 'CAP01';
  static const String codigoRecuerdoEnCapsula = 'CAP03';

  final AccesoTablasRecuerdos _acceso;
  final RepositorioMedios _medios;
  final String? Function() _uidActual;
  final DateTime Function() _reloj;
  final GeneradorIds _generarId;

  String _uid() => _uidActual() ?? (throw const FalloRecuerdo.sinSesion());

  @override
  Future<Recuerdo> crear(NuevoRecuerdo nuevo) async {
    final uid = _uid();
    final ahora = _reloj();
    final fallo = ValidadorRecuerdo.validar(nuevo, hoy: ahora);
    if (fallo != null) throw fallo;
    try {
      final fila = await _fila(uid, nuevo);
      await _acceso.insertar(fila);
      // La fila se arma en el cliente: no hace falta leerla de vuelta.
      final recuerdo = recuerdoDesdeFila({
        ...fila,
        'creado_en': ahora.toUtc().toIso8601String(),
      });
      if (recuerdo == null) throw const FalloRecuerdo.desconocido();
      return recuerdo;
    } catch (error) {
      throw traducirError(error);
    }
  }

  Future<Map<String, dynamic>> _fila(String uid, NuevoRecuerdo nuevo) async {
    final elemento = nuevo.elemento;
    final titulo = nuevo.titulo?.trim();
    final comunes = <String, dynamic>{
      'id': _generarId(),
      'propietario_id': uid,
      'tipo': elemento.tipo.valorBd,
      'titulo': (titulo == null || titulo.isEmpty) ? null : titulo,
      'fecha_recuerdo': fechaParaBd(nuevo.fechaRecuerdo),
    };
    if (elemento.tipo == TipoElemento.texto) {
      return {...comunes, 'contenido_texto': elemento.texto};
    }
    final medio = await _medios.subir(elemento);
    return {
      ...comunes,
      'cloudinary_public_id': medio.publicId,
      'cloudinary_tipo_recurso': medio.tipoRecurso,
      'cloudinary_version': medio.version,
      'formato': medio.formato ?? elemento.formato,
      'bytes': medio.bytes,
      'ancho': medio.ancho,
      'alto': medio.alto,
      'duracion_segundos': _duracion(medio.duracionSegundos, elemento),
    };
  }

  static double? _duracion(double? servidor, ElementoBorrador elemento) {
    if (elemento.tipo != TipoElemento.video &&
        elemento.tipo != TipoElemento.audio) {
      return null;
    }
    final local = elemento.duracion;
    return servidor ?? (local == null ? null : local.inMilliseconds / 1000);
  }

  @override
  Future<List<Recuerdo>> listar(FiltroRecuerdos filtro) async {
    final uid = _uid();
    try {
      final desde = filtro.desde;
      final hasta = filtro.hasta;
      final filas = await _acceso.listar(
        propietarioId: uid,
        tipos: [for (final tipo in filtro.tipos) tipo.valorBd]..sort(),
        desde: desde == null ? null : fechaParaBd(desde),
        hasta: hasta == null ? null : fechaParaBd(hasta),
      );
      return [
        for (final fila in filas) ?recuerdoDesdeFila(fila),
      ];
    } catch (error) {
      throw traducirError(error);
    }
  }

  @override
  Future<Recuerdo?> obtener(String id) async {
    _uid();
    try {
      return recuerdoDesdeFila(await _acceso.leerPorId(id));
    } catch (error) {
      throw traducirError(error);
    }
  }

  @override
  Future<int> contarCapsulasSelladas(String id) async {
    _uid();
    try {
      return await _acceso.contarCapsulasSelladas(id);
    } catch (error) {
      throw traducirError(error);
    }
  }

  @override
  Future<void> eliminar(String id) async {
    _uid();
    int borradas;
    try {
      borradas = await _acceso.eliminar(id);
    } catch (error) {
      throw traducirError(error);
    }
    // RLS (elemento ya entregado o ajeno) filtra el DELETE sin error.
    if (borradas == 0) throw const FalloRecuerdo.permisoDenegado();
  }

  @override
  Future<UsoMedios> leerUsoMedios() async {
    _uid();
    try {
      final fila = await _acceso.leerUsoMedios();
      final usados = fila?['bytes_usados'];
      final limite = fila?['bytes_limite'];
      return UsoMedios(
        bytesUsados: usados is num ? usados.toInt() : 0,
        bytesLimite: limite is num
            ? limite.toInt()
            : const UsoMedios(bytesUsados: 0).bytesLimite,
      );
    } catch (error) {
      throw traducirError(error);
    }
  }

  /// Traduce errores de PostgREST, red y medios a fallos de dominio.
  @visibleForTesting
  static FalloApp traducirError(Object error) {
    if (error is FalloApp) return error;
    if (error is PostgrestException) {
      switch (error.code) {
        case codigoCuotaExcedida:
          return const FalloMedios.cuotaExcedida();
        case codigoRecuerdoEnCapsula:
          return const FalloRecuerdo.enCapsulaSellada();
        case ErroresPostgrest.permisoDenegado:
          return const FalloRecuerdo.permisoDenegado();
        case '23514':
          return const FalloRecuerdo.datoInvalido();
        case final codigo? when ErroresPostgrest.sesionInvalida.contains(codigo):
          return const FalloRecuerdo.sesionVencida();
      }
      debugPrint('Capsoul: PostgrestException no esperada: $error');
      return const FalloRecuerdo.desconocido();
    }
    if (error is SocketException || error is TimeoutException) {
      return const FalloRecuerdo.sinRed();
    }
    debugPrint('Capsoul: error de recuerdos no esperado: $error');
    return const FalloRecuerdo.desconocido();
  }
}
