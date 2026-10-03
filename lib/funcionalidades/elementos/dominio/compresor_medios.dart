import 'elemento_borrador.dart';

/// Prepara en el teléfono los archivos capturados (compresión y medición)
/// antes de agregarlos a una cápsula. Lanza [FalloMedios] si el archivo no
/// cumple [LimitesMedios] tras comprimirlo.
abstract interface class CompresorMedios {
  Future<ElementoBorrador> prepararFoto(String rutaOriginal);

  Future<ElementoBorrador> prepararVideo(String ruta, Duration duracion);

  Future<ElementoBorrador> prepararAudio(
    String ruta,
    Duration duracion,
    List<double> muestrasOnda,
  );
}
