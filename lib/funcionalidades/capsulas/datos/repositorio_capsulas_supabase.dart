import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../nucleo/errores/fallo_app.dart';
import '../../../nucleo/identificadores/generador_ids.dart';
import '../../../nucleo/infraestructura/traductor_errores_backend.dart';
import '../../elementos/dominio/fallo_medios.dart';
import '../../recuerdos/datos/mapeo_recuerdos.dart';
import '../../recuerdos/dominio/recuerdo.dart';
import '../dominio/capsula.dart';
import '../dominio/estado_capsula.dart';
import '../dominio/fallo_capsula.dart';
import '../dominio/nueva_capsula.dart';
import '../dominio/repositorio_capsulas.dart';
import '../dominio/validador_capsula.dart';
import 'acceso_tablas_capsulas.dart';

/// [RepositorioCapsulas] con Supabase (migraciones 000001, 000003 y 000004).
///
/// Los recuerdos ya existen en `elementos` (banco de recuerdos). Orden al
/// crear (respeta las políticas RLS): insertar la cápsula en `borrador` (id
/// generado en el cliente) → unir los recuerdos en `capsula_elementos` con su
/// orden → pasarla a `programada`. Si algo falla se borra solo la cápsula
/// (sus enlaces caen en cascada); los recuerdos no se tocan.
class RepositorioCapsulasSupabase implements RepositorioCapsulas {
  RepositorioCapsulasSupabase({
    required this._acceso,
    required this._uidActual,
    DateTime Function()? reloj,
    GeneradorIds? generarId,
  })  : _reloj = reloj ?? DateTime.now,
        _generarId = generarId ?? generarIdAleatorio;

  /// SQLSTATE propios de la migración 000003.
  static const String codigoCuotaExcedida = 'CAP01';
  static const String codigoMaximoElementos = 'CAP02';

  final AccesoTablasCapsulas _acceso;
  final String? Function() _uidActual;
  final DateTime Function() _reloj;
  final GeneradorIds _generarId;

  @override
  Future<String> crearCapsula(NuevaCapsula nueva) async {
    final uid = _uidActual();
    if (uid == null) throw const FalloCapsula.sinSesion();
    final fallo = ValidadorCapsula.validar(nueva, ahora: _reloj());
    if (fallo != null) throw fallo;

    final idCapsula = _generarId();
    var insertada = false;
    try {
      final mensaje = nueva.mensaje?.trim();
      await _acceso.insertarCapsula({
        'id': idCapsula,
        'autor_id': uid,
        'titulo': nueva.titulo.trim(),
        'mensaje': (mensaje == null || mensaje.isEmpty) ? null : mensaje,
        'fecha_apertura': nueva.fechaApertura.toUtc().toIso8601String(),
        'estado': EstadoCapsula.borrador.valorBd,
      });
      insertada = true;
      await _acceso.insertarEnlaces([
        for (var i = 0; i < nueva.recuerdos.length; i++)
          {
            'capsula_id': idCapsula,
            'elemento_id': nueva.recuerdos[i].id,
            'orden': i,
          },
      ]);
      await _acceso.actualizarEstadoCapsula(
        idCapsula,
        EstadoCapsula.programada.valorBd,
      );
      return idCapsula;
    } catch (error) {
      if (insertada) await _deshacer(idCapsula);
      throw traducirError(error);
    }
  }

  /// Compensación best effort: borra la cápsula incompleta (aún en borrador).
  Future<void> _deshacer(String idCapsula) async {
    try {
      await _acceso.eliminarCapsula(idCapsula);
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
    final ordenados = <(int, Recuerdo)>[
      if (enlaces is List)
        for (final enlace in enlaces) ?recuerdoDesdeEnlace(enlace),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    return Capsula(
      id: id,
      autorId: autorId,
      titulo: titulo,
      mensaje: mensaje is String ? mensaje : null,
      fechaApertura: _fecha(fila['fecha_apertura']),
      estado: estado,
      liberadaEn: _fecha(fila['liberada_en']),
      creadoEn: creadoEn,
      elementos: List.unmodifiable([for (final (_, r) in ordenados) r]),
    );
  }

  /// Recuerdo de un enlace `capsula_elementos(orden, elementos(...))` con
  /// su orden, o `null` si está mal formado.
  @visibleForTesting
  static (int, Recuerdo)? recuerdoDesdeEnlace(Object? enlace) {
    if (enlace is! Map) return null;
    final recuerdo = recuerdoDesdeFila(enlace['elementos']);
    if (recuerdo == null) return null;
    final orden = enlace['orden'];
    return (orden is num ? orden.toInt() : 0, recuerdo);
  }

  static DateTime? _fecha(Object? valor) =>
      valor is String ? DateTime.tryParse(valor) : null;

  /// Mensaje de permiso según la tabla que rechazó la operación.
  @visibleForTesting
  static FalloCapsula falloPermisoPorTabla(String? tabla) => switch (tabla) {
        'elementos' => const FalloCapsula.permisoRecuerdo(),
        'capsula_elementos' => const FalloCapsula.permisoEnlace(),
        _ => const FalloCapsula.permisoDenegado(),
      };

  /// Traduce errores de PostgREST, red y medios a fallos de dominio.
  @visibleForTesting
  static FalloApp traducirError(Object error) {
    if (error is FalloApp) return error;
    if (error is ErrorPostgrest) {
      switch (error.codigo) {
        case codigoCuotaExcedida:
          return const FalloMedios.cuotaExcedida();
        case codigoMaximoElementos:
          return const FalloCapsula.demasiadosElementos();
        case TraductorErroresBackend.permisoDenegado:
          return falloPermisoPorTabla(
            TraductorErroresBackend.tablaDeViolacionRls(error.mensaje),
          );
        case final codigo?
            when TraductorErroresBackend.sesionInvalida.contains(codigo):
          return const FalloCapsula.sesionVencida();
        case 'P0001' when error.mensaje.contains('fecha de apertura'):
          return const FalloCapsula.fechaInvalida();
        case '23514':
          return const FalloCapsula(
            'dato_invalido',
            'Algún dato de la cápsula no cumple los límites permitidos.',
          );
        case '23503':
          return const FalloCapsula(
            'recuerdo_no_existe',
            'Uno de los recuerdos ya no existe. Quítalo y vuelve a intentarlo.',
          );
      }
      debugPrint('Capsoul: ErrorPostgrest no esperado: $error');
      return const FalloCapsula.desconocido();
    }
    if (error is SocketException || error is TimeoutException) {
      return const FalloCapsula.sinRed();
    }
    debugPrint('Capsoul: error de cápsulas no esperado: $error');
    return const FalloCapsula.desconocido();
  }
}
