import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../../funcionalidades/elementos/dominio/fallo_medios.dart';
import '../../../../funcionalidades/elementos/dominio/medio_subido.dart';
import '../../cliente_almacenamiento.dart';

/// [ClienteAlmacenamiento] que sube archivos a Cloudinary con firma del
/// servidor.
class ClienteAlmacenamientoCloudinary implements ClienteAlmacenamiento {
  ClienteAlmacenamientoCloudinary({http.Client? clienteHttp})
      : _http = clienteHttp ?? http.Client();

  static const Duration _tiempoMaximo = Duration(minutes: 3);

  final http.Client _http;

  @override
  Future<MedioSubido> subirArchivo({
    required String rutaLocal,
    required String urlSubida,
    required Map<String, String> parametrosFirma,
  }) async {
    try {
      final solicitud =
          http.MultipartRequest('POST', Uri.parse(urlSubida))
            ..fields.addAll(parametrosFirma)
            ..files.add(await http.MultipartFile.fromPath('file', rutaLocal));
      final respuesta = await http.Response.fromStream(
        await _http.send(solicitud).timeout(_tiempoMaximo),
      );
      if (respuesta.statusCode != 200) {
        debugPrint(
          'Capsoul: Cloudinary respondió ${respuesta.statusCode}: '
          '${respuesta.body}',
        );
        throw const FalloMedios.subidaFallida();
      }
      final medio = _medioDesdeRespuesta(jsonDecode(respuesta.body));
      if (medio == null) throw const FalloMedios.subidaFallida();
      return medio;
    } on FalloMedios {
      rethrow;
    } on SocketException {
      throw const FalloMedios.sinRed();
    } on TimeoutException {
      throw const FalloMedios.sinRed();
    } on http.ClientException {
      throw const FalloMedios.sinRed();
    } catch (error) {
      debugPrint('Capsoul: error al subir a Cloudinary: $error');
      throw const FalloMedios.subidaFallida();
    }
  }

  @visibleForTesting
  static MedioSubido? _medioDesdeRespuesta(Object? datos) {
    if (datos is! Map) return null;
    final publicId = datos['public_id'];
    final tipoRecurso = datos['resource_type'];
    final tipoEntrega = datos['type'];
    final bytes = datos['bytes'];
    if (publicId is! String ||
        tipoRecurso is! String ||
        tipoEntrega != 'authenticated' ||
        bytes is! num) {
      return null;
    }
    final version = datos['version'];
    final formato = datos['format'];
    final ancho = datos['width'];
    final alto = datos['height'];
    final duracion = datos['duration'];
    return MedioSubido(
      publicId: publicId,
      tipoRecurso: tipoRecurso,
      bytes: bytes.toInt(),
      version: version is num ? version.toInt() : null,
      formato: formato is String ? formato : null,
      ancho: ancho is num ? ancho.toInt() : null,
      alto: alto is num ? alto.toInt() : null,
      duracionSegundos: duracion is num ? duracion.toDouble() : null,
    );
  }

  void liberarRecursos() => _http.close();
}
