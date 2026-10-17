import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';

import '../dominio/compresor_medios.dart';
import '../dominio/elemento_borrador.dart';
import '../dominio/fallo_medios.dart';
import '../dominio/importador_medios.dart';
import '../dominio/tipo_elemento.dart';

/// Galería y archivos locales vía [ImagePicker] y [FilePicker].
class ImportadorMediosDispositivo implements ImportadorMedios {
  ImportadorMediosDispositivo(this._compresor, {ImagePicker? selectorImagen})
      : _selectorImagen = selectorImagen ?? ImagePicker();

  final CompresorMedios _compresor;
  final ImagePicker _selectorImagen;

  @override
  Future<ElementoBorrador?> importar(TipoElemento tipo) async {
    return switch (tipo) {
      TipoElemento.foto => _importarFoto(),
      TipoElemento.video => _importarVideo(),
      TipoElemento.audio => _importarAudio(),
      TipoElemento.texto || TipoElemento.musica => null,
    };
  }

  Future<ElementoBorrador?> _importarFoto() async {
    final archivo = await _selectorImagen.pickImage(source: ImageSource.gallery);
    if (archivo == null) return null;
    return _compresor.prepararFoto(archivo.path);
  }

  Future<ElementoBorrador?> _importarVideo() async {
    final archivo = await _selectorImagen.pickVideo(source: ImageSource.gallery);
    if (archivo == null) return null;
    final duracion = await _duracionVideo(archivo.path);
    return _compresor.prepararVideo(archivo.path, duracion);
  }

  Future<ElementoBorrador?> _importarAudio() async {
    final resultado = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['m4a', 'mp3', 'aac', 'wav', 'ogg', 'flac'],
    );
    final ruta = resultado?.files.single.path;
    if (ruta == null) return null;
    final duracion = await _duracionAudio(ruta);
    return _compresor.prepararAudio(ruta, duracion, const []);
  }

  static Future<Duration> _duracionVideo(String ruta) async {
    final controlador = VideoPlayerController.file(File(ruta));
    try {
      await controlador.initialize();
      return controlador.value.duration;
    } catch (error) {
      debugPrint('Capsoul: no se pudo leer la duración del video: $error');
      throw const FalloMedios.capturaFallida();
    } finally {
      await controlador.dispose();
    }
  }

  static Future<Duration> _duracionAudio(String ruta) async {
    final reproductor = AudioPlayer();
    try {
      final duracion = await reproductor.setFilePath(ruta);
      if (duracion == null) throw const FalloMedios.capturaFallida();
      return duracion;
    } catch (error) {
      debugPrint('Capsoul: no se pudo leer la duración del audio: $error');
      throw const FalloMedios.capturaFallida();
    } finally {
      await reproductor.dispose();
    }
  }
}
