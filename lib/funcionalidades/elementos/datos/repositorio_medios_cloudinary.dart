import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../dominio/elemento_borrador.dart';
import '../dominio/fallo_medios.dart';
import '../dominio/medio_subido.dart';
import '../dominio/repositorio_medios.dart';
import 'cliente_firma_subida.dart';

/// [RepositorioMedios] con subida firmada directa a Cloudinary: el servidor
/// firma (`firmar-subida`, con `type=authenticated` y `public_id`
/// aleatorio) y la app sube el archivo ya comprimido. El API secret nunca
/// está en la app.
class RepositorioMediosCloudinary implements RepositorioMedios {
  RepositorioMediosCloudinary(this._firmas, {http.Client? clienteHttp})
      : _http = clienteHttp ?? http.Client();

  final ClienteFirmaSubida _firmas;
  final http.Client _http;

  static const Duration _tiempoMaximo = Duration(minutes: 3);

  @override
  Future<MedioSubido> subir(ElementoBorrador elemento) async {
    final ruta = elemento.rutaArchivo;
    if (!elemento.tipo.esMedio || ruta == null) {
      throw const FalloMedios.subidaFallida();
    }
    final firma = await _firmas.solicitarFirma(
      tipo: elemento.tipo,
      bytes: elemento.bytes,
      duracion: elemento.duracion,
      formato: elemento.formato,
    );
    try {
      final solicitud =
          http.MultipartRequest('POST', Uri.parse(firma.urlSubida))
            ..fields.addAll(firma.parametros)
            ..files.add(await http.MultipartFile.fromPath('file', ruta));
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
      final medio = medioDesdeRespuesta(jsonDecode(respuesta.body));
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

  /// Mapea la respuesta JSON de Cloudinary. Falla cerrado (`null`) si falta
  /// algún dato obligatorio o la entrega no es `authenticated`.
  @visibleForTesting
  static MedioSubido? medioDesdeRespuesta(Object? datos) {
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
