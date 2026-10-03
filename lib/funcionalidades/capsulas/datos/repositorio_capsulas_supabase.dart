import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../nucleo/errores/fallo_app.dart';
import '../../elementos/dominio/elemento_borrador.dart';
import '../../elementos/dominio/fallo_medios.dart';
import '../../elementos/dominio/repositorio_medios.dart';
import '../../elementos/dominio/tipo_elemento.dart';
import '../dominio/capsula.dart';
import '../dominio/estado_capsula.dart';
import '../dominio/fallo_capsula.dart';
import '../dominio/nueva_capsula.dart';
import '../dominio/repositorio_capsulas.dart';
import '../dominio/validador_capsula.dart';
import 'acceso_tablas_capsulas.dart';

/// [RepositorioCapsulas] con Supabase (tablas de la migración 000001) y
/// medios en Cloudinary vía [RepositorioMedios].
///
/// Orden al crear (respeta las políticas RLS): subir medios → insertar
/// `elementos` → insertar la cápsula en `borrador` → unir en
/// `capsula_elementos` → pasarla a `programada`. Si algo falla se borran la
/// cápsula (aún en borrador) y los elementos insertados.
class RepositorioCapsulasSupabase implements RepositorioCapsulas {
  RepositorioCapsulasSupabase({
    required this._acceso,
    required this._medios,
    required this._uidActual,
    DateTime Function()? reloj,
  }) : _reloj = reloj ?? DateTime.now;

  /// SQLSTATE propios de la migración 000003.
  static const String codigoCuotaExcedida = 'CAP01';
  static const String codigoMaximoElementos = 'CAP02';

  final AccesoTablasCapsulas _acceso;
  final RepositorioMedios _medios;
  final String? Function() _uidActual;
  final DateTime Function() _reloj;

  @override
  Future<String> crearCapsula(
    NuevaCapsula nueva, {
    void Function(int guardados, int total)? alProgreso,
  }) async {
    final uid = _uidActual();
    if (uid == null) throw const FalloCapsula.sinSesion();
    final fallo = ValidadorCapsula.validar(nueva, ahora: _reloj());
    if (fallo != null) throw fallo;

    final total = nueva.elementos.length;
    final idsElementos = <String>[];
    String? idCapsula;
    try {
      alProgreso?.call(0, total);
      for (final elemento in nueva.elementos) {
        final fila = await _filaElemento(uid, elemento);
        idsElementos.add(await _acceso.insertarElemento(fila));
        alProgreso?.call(idsElementos.length, total);
      }
      final mensaje = nueva.mensaje?.trim();
      idCapsula = await _acceso.insertarCapsula({
        'autor_id': uid,
        'titulo': nueva.titulo.trim(),
        'mensaje': (mensaje == null || mensaje.isEmpty) ? null : mensaje,
        'fecha_apertura': nueva.fechaApertura.toUtc().toIso8601String(),
        'estado': EstadoCapsula.borrador.valorBd,
      });
      final capsulaId = idCapsula;
      await _acceso.insertarEnlaces([
        for (var i = 0; i < idsElementos.length; i++)
          {'capsula_id': capsulaId, 'elemento_id': idsElementos[i], 'orden': i},
      ]);
      await _acceso.actualizarEstadoCapsula(
        capsulaId,
        EstadoCapsula.programada.valorBd,
      );
      return capsulaId;
    } catch (error) {
      await _deshacer(idCapsula, idsElementos);
      throw traducirError(error);
    }
  }

  Future<Map<String, dynamic>> _filaElemento(
    String uid,
    ElementoBorrador elemento,
  ) async {
    if (elemento.tipo == TipoElemento.texto) {
      return {
        'propietario_id': uid,
        'tipo': TipoElemento.texto.valorBd,
        'contenido_texto': elemento.texto,
      };
    }
    final medio = await _medios.subir(elemento);
    final duracionLocal = elemento.duracion;
    final duracion = medio.duracionSegundos ??
        (duracionLocal == null ? null : duracionLocal.inMilliseconds / 1000);
    return {
      'propietario_id': uid,
      'tipo': elemento.tipo.valorBd,
      'cloudinary_public_id': medio.publicId,
      'cloudinary_tipo_recurso': medio.tipoRecurso,
      'cloudinary_version': medio.version,
      'formato': medio.formato ?? elemento.formato,
      'bytes': medio.bytes,
      'ancho': medio.ancho,
      'alto': medio.alto,
      'duracion_segundos': duracion,
    };
  }

  /// Compensación best effort: los archivos ya subidos a Cloudinary quedan
  /// huérfanos y los limpiará el servidor (pendiente en Memory.md).
  Future<void> _deshacer(String? idCapsula, List<String> idsElementos) async {
    try {
      if (idCapsula != null) await _acceso.eliminarCapsula(idCapsula);
      await _acceso.eliminarElementos(idsElementos);
    } catch (error) {
      debugPrint('Capsoul: no se pudo deshacer la cápsula incompleta: $error');
    }
  }

  @override
  Future<List<Capsula>> listarMisCapsulas() async {
    final uid = _uidActual();
    if (uid == null) throw const FalloCapsula.sinSesion();
    try {
      final filas = await _acceso.leerCapsulasDeAutor(uid);
      return [
        for (final fila in filas) ?capsulaDesdeFila(fila),
      ];
    } catch (error) {
      throw traducirError(error);
    }
  }

  @override
  Future<Capsula?> obtenerCapsula(String id) async {
    try {
      final fila = await _acceso.leerCapsulaConElementos(id);
      return fila == null ? null : capsulaDesdeFila(fila);
    } catch (error) {
      throw traducirError(error);
    }
  }

  /// Falla cerrado: una fila sin id, autor, título, estado o fecha de
  /// creación válidos se descarta. Los elementos mal formados se omiten.
  @visibleForTesting
  static Capsula? capsulaDesdeFila(Map<String, dynamic> fila) {
    final id = fila['id'];
    final autorId = fila['autor_id'];
    final titulo = fila['titulo'];
    final estado = EstadoCapsula.desdeValorBd(fila['estado']);
    final creadoEn = _fecha(fila['creado_en']);
    if (id is! String ||
        autorId is! String ||
        titulo is! String ||
        estado == null ||
        creadoEn == null) {
      debugPrint('Capsoul: fila de capsulas con formato inválido');
      return null;
    }
    final mensaje = fila['mensaje'];
    final enlaces = fila['capsula_elementos'];
    final elementos = <ElementoCapsula>[
      if (enlaces is List)
        for (final enlace in enlaces) ?elementoDesdeEnlace(enlace),
    ]..sort((a, b) => a.orden.compareTo(b.orden));
    return Capsula(
      id: id,
      autorId: autorId,
      titulo: titulo,
      mensaje: mensaje is String ? mensaje : null,
      fechaApertura: _fecha(fila['fecha_apertura']),
      estado: estado,
      liberadaEn: _fecha(fila['liberada_en']),
      creadoEn: creadoEn,
      elementos: List.unmodifiable(elementos),
    );
  }

  @visibleForTesting
  static ElementoCapsula? elementoDesdeEnlace(Object? enlace) {
    if (enlace is! Map) return null;
    final elemento = enlace['elementos'];
    if (elemento is! Map) return null;
    final id = elemento['id'];
    final tipo = TipoElemento.desdeValorBd(elemento['tipo']);
    if (id is! String || tipo == null) return null;
    final orden = enlace['orden'];
    final texto = elemento['contenido_texto'];
    final publicId = elemento['cloudinary_public_id'];
    final bytes = elemento['bytes'];
    final duracion = elemento['duracion_segundos'];
    return ElementoCapsula(
      id: id,
      tipo: tipo,
      orden: orden is num ? orden.toInt() : 0,
      contenidoTexto: texto is String ? texto : null,
      publicId: publicId is String ? publicId : null,
      bytes: bytes is num ? bytes.toInt() : null,
      duracion: duracion is num
          ? Duration(milliseconds: (duracion * 1000).round())
          : null,
    );
  }

  static DateTime? _fecha(Object? valor) =>
      valor is String ? DateTime.tryParse(valor) : null;

  /// Traduce errores de PostgREST, red y medios a fallos de dominio.
  @visibleForTesting
  static FalloApp traducirError(Object error) {
    if (error is FalloApp) return error;
    if (error is PostgrestException) {
      switch (error.code) {
        case codigoCuotaExcedida:
          return const FalloMedios.cuotaExcedida();
        case codigoMaximoElementos:
          return const FalloCapsula.demasiadosElementos();
        case '42501' || 'PGRST301' || 'PGRST302' || 'PGRST303':
          return const FalloCapsula.permisoDenegado();
        case 'P0001' when error.message.contains('fecha de apertura'):
          return const FalloCapsula.fechaInvalida();
        case '23514':
          return const FalloCapsula(
            'dato_invalido',
            'Algún recuerdo no cumple los límites permitidos.',
          );
      }
      debugPrint('Capsoul: PostgrestException no esperada: $error');
      return const FalloCapsula.desconocido();
    }
    if (error is SocketException || error is TimeoutException) {
      return const FalloCapsula.sinRed();
    }
    debugPrint('Capsoul: error de cápsulas no esperado: $error');
    return const FalloCapsula.desconocido();
  }
}
