import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

import '../dominio/compresor_medios.dart';
import '../dominio/elemento_borrador.dart';
import '../dominio/fallo_medios.dart';
import '../dominio/limites_medios.dart';
import '../dominio/tipo_elemento.dart';
import '../dominio/validador_medios.dart';

/// [CompresorMedios] en el teléfono:
/// - foto: JPEG calidad 75 con el lado mayor ≤ 1600 px (flutter_image_compress);
/// - video y audio: ya salen comprimidos de la captura (720p ~2,5 Mbps y AAC
///   mono 64 kbps); aquí solo se miden y se validan contra los topes.
class CompresorMediosDispositivo implements CompresorMedios {
  @override
  Future<ElementoBorrador> prepararFoto(
    String rutaOriginal, {
    int rotacionGrados = 0,
    bool esCamaraFrontal = false,
  }) async {
    final dimensiones = await _leerDimensiones(rutaOriginal);
    final objetivo = ValidadorMedios.dimensionesObjetivoFoto(
      dimensiones.ancho,
      dimensiones.alto,
    );
    // flutter_image_compress escala para que el lado MENOR llegue a
    // minWidth/minHeight; pasar el lado menor objetivo en ambos acota el
    // lado mayor a 1600 px sin importar la orientación (EXIF).
    final ladoMenor = objetivo.ancho < objetivo.alto
        ? objetivo.ancho
        : objetivo.alto;
    final destino = await _rutaTemporal('jpg');
    final XFile? resultado;
    try {
      resultado = await FlutterImageCompress.compressAndGetFile(
        rutaOriginal,
        destino,
        minWidth: ladoMenor,
        minHeight: ladoMenor,
        quality: LimitesMedios.calidadJpegFoto,
        format: CompressFormat.jpeg,
        rotate: rotacionGrados % 360,
        autoCorrectionAngle: true,
      );
    } catch (error) {
      debugPrint('Capsoul: no se pudo comprimir la foto: $error');
      throw const FalloMedios.compresionFallida();
    }
    if (resultado == null) throw const FalloMedios.compresionFallida();
    var rutaFinal = resultado.path;
    if (esCamaraFrontal) {
      rutaFinal = await _voltearHorizontalEnArchivo(rutaFinal);
    }
    final bytes = await File(rutaFinal).length();
    final finales = await _leerDimensiones(rutaFinal);
    _validar(TipoElemento.foto, bytes, null);
    return ElementoBorrador(
      idLocal: ElementoBorrador.nuevoIdLocal(),
      tipo: TipoElemento.foto,
      rutaArchivo: rutaFinal,
      bytes: bytes,
      ancho: finales.ancho,
      alto: finales.alto,
      formato: 'jpg',
    );
  }

  @override
  Future<ElementoBorrador> prepararVideo(String ruta, Duration duracion) async {
    final bytes = await _medir(ruta);
    _validar(TipoElemento.video, bytes, duracion);
    return ElementoBorrador(
      idLocal: ElementoBorrador.nuevoIdLocal(),
      tipo: TipoElemento.video,
      rutaArchivo: ruta,
      bytes: bytes,
      duracion: duracion,
      formato: _extension(ruta, 'mp4'),
    );
  }

  @override
  Future<ElementoBorrador> prepararAudio(
    String ruta,
    Duration duracion,
    List<double> muestrasOnda,
  ) async {
    final bytes = await _medir(ruta);
    _validar(TipoElemento.audio, bytes, duracion);
    return ElementoBorrador(
      idLocal: ElementoBorrador.nuevoIdLocal(),
      tipo: TipoElemento.audio,
      rutaArchivo: ruta,
      bytes: bytes,
      duracion: duracion,
      formato: _extension(ruta, 'm4a'),
      muestrasOnda: List.unmodifiable(muestrasOnda),
    );
  }

  static void _validar(TipoElemento tipo, int bytes, Duration? duracion) {
    final fallo = ValidadorMedios.validarMedio(
      tipo: tipo,
      bytes: bytes,
      duracion: duracion,
    );
    if (fallo != null) throw fallo;
  }

  static Future<int> _medir(String ruta) async {
    try {
      return await File(ruta).length();
    } on FileSystemException catch (error) {
      debugPrint('Capsoul: no se pudo leer el archivo capturado: $error');
      throw const FalloMedios.capturaFallida();
    }
  }

  /// Ancho y alto sin decodificar la imagen completa (p. ej. preview tras captura).
  static Future<({int ancho, int alto})> leerDimensionesImagen(String ruta) =>
      _leerDimensiones(ruta);

  /// Voltea el JPEG en horizontal (cámara frontal → archivo sin espejo de selfie).
  static Future<String> _voltearHorizontalEnArchivo(String rutaJpeg) async {
    try {
      final bytes = await File(rutaJpeg).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final ancho = image.width;
      final alto = image.height;

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.translate(ancho.toDouble(), 0);
      canvas.scale(-1, 1);
      canvas.drawImage(image, ui.Offset.zero, ui.Paint());
      image.dispose();

      final picture = recorder.endRecording();
      final volteada = await picture.toImage(ancho, alto);
      picture.dispose();

      final png = await volteada.toByteData(format: ui.ImageByteFormat.png);
      volteada.dispose();
      if (png == null) throw const FalloMedios.compresionFallida();

      final jpeg = await FlutterImageCompress.compressWithList(
        Uint8List.view(png.buffer, png.offsetInBytes, png.lengthInBytes),
        quality: LimitesMedios.calidadJpegFoto,
        format: CompressFormat.jpeg,
        autoCorrectionAngle: false,
      );

      final salida = await _rutaTemporal('jpg');
      await File(salida).writeAsBytes(jpeg, flush: true);
      if (salida != rutaJpeg) {
        try {
          await File(rutaJpeg).delete();
        } catch (_) {}
      }
      return salida;
    } catch (error) {
      debugPrint('Capsoul: no se pudo voltear la foto frontal: $error');
      throw const FalloMedios.compresionFallida();
    }
  }

  static Future<({int ancho, int alto})> _leerDimensiones(String ruta) async {
    try {
      final bufer = await ui.ImmutableBuffer.fromFilePath(ruta);
      final descriptor = await ui.ImageDescriptor.encoded(bufer);
      final dimensiones = (ancho: descriptor.width, alto: descriptor.height);
      descriptor.dispose();
      bufer.dispose();
      return dimensiones;
    } catch (error) {
      debugPrint('Capsoul: no se pudo leer la foto: $error');
      throw const FalloMedios.compresionFallida();
    }
  }

  static Future<String> _rutaTemporal(String extension) async {
    final carpeta = await getTemporaryDirectory();
    final nombre = 'capsoul_${DateTime.now().microsecondsSinceEpoch}.$extension';
    return '${carpeta.path}${Platform.pathSeparator}$nombre';
  }

  static String _extension(String ruta, String porDefecto) {
    final punto = ruta.lastIndexOf('.');
    if (punto < 0 || punto == ruta.length - 1) return porDefecto;
    return ruta.substring(punto + 1).toLowerCase();
  }
}
