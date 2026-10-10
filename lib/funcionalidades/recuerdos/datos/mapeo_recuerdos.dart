import 'package:flutter/foundation.dart';

import '../../elementos/dominio/tipo_elemento.dart';
import '../../musica/dominio/referencia_musica.dart';
import '../dominio/recuerdo.dart';

/// Columnas de `elementos` que la app lee (también en selects anidados de
/// cápsulas y momentos).
const String columnasRecuerdo =
    'id, propietario_id, tipo, titulo, fecha_recuerdo, creado_en, '
    'contenido_texto, cloudinary_public_id, formato, bytes, ancho, alto, '
    'duracion_segundos, musica_proveedor, musica_id_externo, musica_titulo, '
    'musica_artista, musica_preview_url, musica_url_completa, musica_portada_url, '
    'musica_uri_profundo, musica_enlace_deezer';

/// `2026-10-03` (fecha local, sin hora) para la columna `date`.
String fechaParaBd(DateTime fecha) {
  String dos(int n) => n.toString().padLeft(2, '0');
  return '${fecha.year.toString().padLeft(4, '0')}-${dos(fecha.month)}-'
      '${dos(fecha.day)}';
}

/// Lee una columna `date` como día local.
DateTime? fechaDesdeBd(Object? valor) {
  if (valor is! String || valor.length < 10) return null;
  final fecha = DateTime.tryParse(valor.substring(0, 10));
  return fecha == null ? null : DateTime(fecha.year, fecha.month, fecha.day);
}

/// Mapea una fila de `elementos`. Falla cerrado (`null`) si falta algo
/// obligatorio o el tipo no se reconoce.
Recuerdo? recuerdoDesdeFila(Object? datos) {
  if (datos is! Map) return null;
  final id = datos['id'];
  final propietario = datos['propietario_id'];
  final tipo = TipoElemento.desdeValorBd(datos['tipo']);
  final creado = datos['creado_en'];
  final creadoEn = creado is String ? DateTime.tryParse(creado) : null;
  if (id is! String || propietario is! String || tipo == null ||
      creadoEn == null) {
    return null;
  }
  final fecha = fechaDesdeBd(datos['fecha_recuerdo']) ??
      DateTime(creadoEn.year, creadoEn.month, creadoEn.day);
  final duracion = datos['duracion_segundos'];
  final musica = ReferenciaMusica.desdeFilaBd(
    Map<dynamic, dynamic>.from(datos),
  );
  if (tipo == TipoElemento.musica && musica == null) {
    debugPrint(
      'recuerdoDesdeFila: tipo musica sin metadatos musica (id=$id)',
    );
  }
  return Recuerdo(
    id: id,
    propietarioId: propietario,
    tipo: tipo,
    fechaRecuerdo: fecha,
    creadoEn: creadoEn,
    titulo: _texto(datos['titulo']),
    contenidoTexto: _texto(datos['contenido_texto']),
    publicId: _texto(datos['cloudinary_public_id']),
    formato: _texto(datos['formato']),
    bytes: _entero(datos['bytes']),
    ancho: _entero(datos['ancho']),
    alto: _entero(datos['alto']),
    duracion: duracion is num
        ? Duration(milliseconds: (duracion * 1000).round())
        : (duracion is String
            ? _duracionDesdeTexto(duracion)
            : null),
    musica: musica,
  );
}

String? _texto(Object? valor) => valor is String ? valor : null;

int? _entero(Object? valor) => valor is num ? valor.toInt() : null;

/// `numeric` puede llegar como texto desde PostgREST.
Duration? _duracionDesdeTexto(String valor) {
  final segundos = double.tryParse(valor);
  return segundos == null
      ? null
      : Duration(milliseconds: (segundos * 1000).round());
}
