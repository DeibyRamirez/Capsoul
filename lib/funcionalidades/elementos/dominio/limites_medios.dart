import 'tipo_elemento.dart';

/// Límites de medios aprobados por el PO (2026-10-03). Son la única fuente de
/// verdad en la app; la Edge Function `firmar-subida` y la migración
/// `20261003000003_capsoul_limites_medios.sql` usan los mismos valores.
///
/// Los tamaños usan MB binarios (1 MB = 1024 × 1024 bytes).
abstract final class LimitesMedios {
  static const int _mb = 1024 * 1024;

  // Foto: se comprime en el teléfono antes de subir.
  static const int ladoMayorFotoPx = 1600;
  static const int calidadJpegFoto = 75;
  static const int bytesMaxFoto = 2 * _mb;

  // Video: se graba ya comprimido (720p, ~2,5 Mbps) con el paquete camera.
  static const int altoVideoPx = 720;
  static const Duration duracionMaxVideo = Duration(seconds: 60);
  static const int bitrateVideo = 2500000;
  static const int bitrateAudioDeVideo = 64000;
  static const int bytesMaxVideo = 20 * _mb;

  // Audio: AAC-LC mono a 64 kbps; 5 min ≈ 2,4 MB. El tope de 3 MB deja margen
  // para el contenedor .m4a.
  static const int bitrateAudio = 64000;
  static const int canalesAudio = 1;
  static const int frecuenciaMuestreoAudio = 44100;
  static const Duration duracionMaxAudio = Duration(minutes: 5);
  static const int bytesMaxAudio = 3 * _mb;

  // Nota de texto.
  static const int caracteresMaxNota = 5000;

  // Cápsula y cuota (la cuota la valida el servidor).
  static const int elementosMaxPorCapsula = 10;
  static const int cuotaBytesPorUsuario = 200 * _mb;

  /// Holgura al validar duraciones: el codificador puede pasar unas décimas.
  static const Duration toleranciaDuracion = Duration(seconds: 1);

  /// Tope de bytes por tipo (`null` para las notas, que se miden en
  /// caracteres).
  static int? bytesMaximos(TipoElemento tipo) => switch (tipo) {
        TipoElemento.foto => bytesMaxFoto,
        TipoElemento.video => bytesMaxVideo,
        TipoElemento.audio => bytesMaxAudio,
        TipoElemento.texto => null,
      };

  /// Duración máxima por tipo (`null` si el tipo no tiene duración).
  static Duration? duracionMaxima(TipoElemento tipo) => switch (tipo) {
        TipoElemento.video => duracionMaxVideo,
        TipoElemento.audio => duracionMaxAudio,
        TipoElemento.foto || TipoElemento.texto => null,
      };
}
