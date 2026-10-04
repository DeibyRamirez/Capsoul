import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../dominio/archivos_medio.dart';

/// [ArchivosMedio] con flutter_cache_manager: archivos en la carpeta de caché
/// de la app, indexados por la clave (`public_id|variante`), no por la URL.
class ArchivosMedioDispositivo implements ArchivosMedio {
  ArchivosMedioDispositivo({CacheManager? gestor})
      : _gestor = gestor ?? gestorCompartido;

  /// Hasta 400 medios; se borran los que no se usan en 60 días.
  static final CacheManager gestorCompartido = CacheManager(
    Config(
      'capsoul_medios',
      stalePeriod: const Duration(days: 60),
      maxNrOfCacheObjects: 400,
    ),
  );

  final CacheManager _gestor;

  /// El contenido de un `public_id` nunca cambia (es aleatorio y no se
  /// sobrescribe), así que el archivo guardado sirve aunque las cabeceras
  /// HTTP lo den por vencido.
  @override
  Future<File?> enCache(String clave) async =>
      (await _gestor.getFileFromCache(clave))?.file;

  @override
  Future<File> descargar(String url, String clave) async =>
      (await _gestor.downloadFile(url, key: clave)).file;

  @override
  Future<void> vaciar() => _gestor.emptyCache();
}
