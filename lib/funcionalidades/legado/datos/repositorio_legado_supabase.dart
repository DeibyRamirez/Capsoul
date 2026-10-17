import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../nucleo/infraestructura/cliente_postgrest.dart';
import '../../../nucleo/infraestructura/traductor_errores_backend.dart';
import '../dominio/condicion_herencia.dart';
import '../dominio/fallo_legado.dart';
import '../dominio/grupo_legado_beneficiario.dart';
import '../dominio/herencia.dart';
import '../dominio/metadatos_herencia.dart';
import '../dominio/repositorio_legado.dart';

class RepositorioLegadoSupabase implements RepositorioLegado {
  RepositorioLegadoSupabase({
    required this._cliente,
    required this._uidActual,
  });

  static const _uuid = Uuid();

  final ClientePostgrest _cliente;
  final String? Function() _uidActual;

  void _exigirSesion() {
    if (_uidActual() == null) throw FalloLegado.sinSesion;
  }

  Map<String, dynamic>? _primerMapa(dynamic data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is List && data.isNotEmpty && data.first is Map) {
      return Map<String, dynamic>.from(data.first as Map);
    }
    return null;
  }

  @override
  Future<ResumenLegado> obtenerResumen() async {
    _exigirSesion();
    final filas = await _cliente.rpc('legado_resumen');
    final mapa = _primerMapa(filas);
    return ResumenLegado.desdeJson(mapa);
  }

  @override
  Future<List<GrupoLegadoBeneficiario>> listarAgrupadoPorBeneficiario() async {
    _exigirSesion();
    final filas = await _cliente.rpc('legado_agrupado_beneficiario');
    return [
      for (final fila in filas)
        if (fila is Map)
          GrupoLegadoBeneficiario.desdeFila(Map<String, dynamic>.from(fila)),
    ];
  }

  @override
  Future<List<Herencia>> listarPorBeneficiario(String beneficiarioUsuarioId) async {
    _exigirSesion();
    final filas = await _cliente
        .from('herencias')
        .seleccionar()
        .eq('propietario_id', _uidActual()!)
        .eq('beneficiario_usuario_id', beneficiarioUsuarioId)
        .ejecutar();
    return [for (final f in filas) Herencia.desdeFila(f)];
  }

  @override
  Future<DetalleHerencia> obtenerDetalle(String herenciaId) async {
    _exigirSesion();
    final filas = await _cliente.rpc(
      'herencia_detalle',
      parametros: {'p_id': herenciaId},
    );
    final mapa = _primerMapa(filas);
    if (mapa == null) {
      throw const FalloLegado(
        FalloLegado.codigoNoEncontrado,
        'Herencia no encontrada.',
      );
    }
    return DetalleHerencia.desdeJson(mapa);
  }

  @override
  Future<String> crearHerencia({
    required String titulo,
    String? descripcion,
    required String beneficiarioUsuarioId,
    required CondicionHerencia condicion,
    MetadatosHerencia metadatos = const MetadatosHerencia(),
    DateTime? fechaActivacion,
    int? diasInactividad,
    bool activar = false,
  }) async {
    _exigirSesion();
    final uid = _uidActual()!;
    final id = _uuid.v4();
    try {
      await _cliente.from('herencias').insertar({
        'id': id,
        'propietario_id': uid,
        'titulo': titulo.trim(),
        'descripcion': descripcion?.trim(),
        'beneficiario_usuario_id': beneficiarioUsuarioId,
        'condicion_activacion': condicion.valorBd,
        'metadatos': metadatos.aJson(),
        if (fechaActivacion != null)
          'fecha_activacion': fechaActivacion.toUtc().toIso8601String(),
        'dias_inactividad': ?diasInactividad,
        'estado': activar ? 'activa' : 'borrador',
      });
      return id;
    } catch (e) {
      throw _traducir(e);
    }
  }

  @override
  Future<void> actualizarHerencia({
    required String herenciaId,
    String? titulo,
    String? descripcion,
    MetadatosHerencia? metadatos,
    bool? activar,
  }) async {
    _exigirSesion();
    final cambios = <String, dynamic>{};
    if (titulo != null) cambios['titulo'] = titulo.trim();
    if (descripcion != null) cambios['descripcion'] = descripcion.trim();
    if (metadatos != null) cambios['metadatos'] = metadatos.aJson();
    if (activar == true) cambios['estado'] = 'activa';
    if (cambios.isEmpty) return;
    try {
      await _cliente.from('herencias').actualizar(cambios).eq('id', herenciaId).ejecutar();
    } catch (e) {
      throw _traducir(e);
    }
  }

  @override
  Future<void> vincularElementos(String herenciaId, List<String> elementoIds) async {
    _exigirSesion();
    final filas = <Map<String, dynamic>>[];
    var orden = 0;
    for (final elementoId in elementoIds) {
      filas.add({
        'herencia_id': herenciaId,
        'elemento_id': elementoId,
        'orden': orden++,
      });
    }
    if (filas.isEmpty) return;
    await _cliente.from('herencia_elementos').insertarMuchos(filas);
  }

  @override
  Future<void> vincularCapsula(String herenciaId, String capsulaId) async {
    _exigirSesion();
    try {
      await _cliente.rpc(
        'vincular_capsula_herencia',
        parametros: {'p_herencia': herenciaId, 'p_capsula': capsulaId},
      );
    } catch (e) {
      throw _traducir(e);
    }
  }

  @override
  Future<void> establecerPersonaConfianza(String nombreUsuario) async {
    _exigirSesion();
    try {
      await _cliente.rpc(
        'establecer_persona_confianza_legado',
        parametros: {'p_nombre_usuario': nombreUsuario},
      );
    } catch (e) {
      throw _traducir(e);
    }
  }

  @override
  Future<void> quitarPersonaConfianza() async {
    _exigirSesion();
    await _cliente.rpc('quitar_persona_confianza_legado');
  }

  @override
  Future<void> guardarInstrucciones(String? texto) async {
    _exigirSesion();
    await _cliente.rpc(
      'guardar_instrucciones_legado',
      parametros: {'p_texto': texto ?? ''},
    );
  }

  @override
  Future<String?> leerInstrucciones() async {
    _exigirSesion();
    final uid = _uidActual()!;
    final filas = await _cliente
        .from('usuarios')
        .seleccionar('instrucciones_legado')
        .eq('id', uid)
        .ejecutar();
    if (filas.isEmpty) return null;
    return filas.first['instrucciones_legado'] as String?;
  }

  @override
  Future<String?> leerPersonaConfianzaId() async {
    _exigirSesion();
    final uid = _uidActual()!;
    final filas = await _cliente
        .from('usuarios')
        .seleccionar('persona_confianza_legado_id')
        .eq('id', uid)
        .ejecutar();
    if (filas.isEmpty) return null;
    return filas.first['persona_confianza_legado_id'] as String?;
  }

  @override
  Future<void> solicitarRespaldoLegal(String herenciaId) async {
    _exigirSesion();
    await _cliente.rpc(
      'solicitar_respaldo_legal_herencia',
      parametros: {'p_herencia': herenciaId},
    );
  }

  FalloLegado _traducir(Object error) {
    if (error is ErrorPostgrest) {
      final mensaje = error.mensaje;
      if (error.codigo == 'PGRST202' ||
          mensaje.contains('Could not find the function')) {
        return FalloLegado.funcionNoDisponible;
      }
      final traducido = FalloLegado.desdeMensajePostgres(mensaje);
      if (traducido.codigo != FalloLegado.codigoDesconocido) {
        return traducido;
      }
      debugPrint('Capsoul: ErrorPostgrest legado: $error');
    }
    return const FalloLegado(
      FalloLegado.codigoDesconocido,
      'No pudimos completar la operación de legado.',
    );
  }
}
