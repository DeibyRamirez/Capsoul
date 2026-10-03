import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../dominio/archivos_medio.dart';
import '../dominio/enlace_medio.dart';
import '../dominio/repositorio_urls_medio.dart';

/// Medio que se quiere ver: recuerdo, `public_id` y variante.
typedef SolicitudMedio = ({
  String idRecuerdo,
  String publicId,
  VarianteMedio variante,
});

/// Entrega el archivo local de un medio: primero la caché del dispositivo
/// (por `public_id` y variante); si falta, pide el enlace (reutilizando los
/// vigentes) y lo descarga una sola vez aunque varios widgets lo pidan.
class CargadorMedios {
  CargadorMedios({required this.urls, required this.archivos});

  final RepositorioUrlsMedio urls;
  final ArchivosMedio archivos;
  final Map<String, Future<File?>> _enCurso = {};

  Future<File?> archivo(SolicitudMedio solicitud) {
    final clave = claveMedio(solicitud.publicId, solicitud.variante);
    // Llaves en el callback: `remove` devuelve el propio Future y
    // whenComplete esperaría por él (bloqueo).
    return _enCurso[clave] ??= _cargar(solicitud, clave).whenComplete(() {
      _enCurso.remove(clave);
    });
  }

  Future<File?> _cargar(SolicitudMedio solicitud, String clave) async {
    try {
      final guardado = await archivos.enCache(clave);
      if (guardado != null) return guardado;
      final url = await urls.enlace(
        idRecuerdo: solicitud.idRecuerdo,
        publicId: solicitud.publicId,
        variante: solicitud.variante,
      );
      if (url == null) return null;
      return await archivos.descargar(url, clave);
    } catch (error) {
      debugPrint('Capsoul: no se pudo cargar el medio: $error');
      return null;
    }
  }
}
