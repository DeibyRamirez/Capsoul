import 'modo_captura.dart';

import '../../elementos/dominio/limites_medios.dart';

/// Parámetros del módulo crear (inyectables por producto).
class ConfiguracionCrear {
  const ConfiguracionCrear({
    this.modos = const [
      ModoCaptura.video,
      ModoCaptura.foto,
      ModoCaptura.texto,
    ],
    this.duracionesVideo = const [
      Duration(seconds: 15),
      LimitesMedios.duracionMaxVideo,
    ],
    this.duracionMinimaVideo = const Duration(seconds: 1),
  });

  final List<ModoCaptura> modos;
  final List<Duration> duracionesVideo;
  final Duration duracionMinimaVideo;

  static const ConfiguracionCrear porDefecto = ConfiguracionCrear();
}
