import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

import '../../dominio/fallo_medios.dart';
import '../../dominio/limites_medios.dart';

/// Abre la cámara (frontal o trasera), permite cambiarla y la libera. Lo
/// usan las pantallas de foto y de video.
class GestorCamara extends ChangeNotifier {
  GestorCamara({required this.paraVideo});

  /// `true`: 720p con audio y bitrate de [LimitesMedios]; `false`: foto en
  /// alta resolución (luego se comprime a 1600 px).
  final bool paraVideo;

  List<CameraDescription> _camaras = const [];
  int _indice = 0;
  bool _liberado = false;
  bool _cambiando = false;

  CameraController? _controlador;
  FalloMedios? _error;

  CameraController? get controlador => _controlador;
  FalloMedios? get error => _error;
  bool get cambiando => _cambiando;
  bool get puedeCambiar => _camaras.length > 1;
  bool get lista => _controlador?.value.isInitialized ?? false;

  bool get esFrontal =>
      _camaras.isNotEmpty &&
      _camaras[_indice].lensDirection == CameraLensDirection.front;

  Future<void> iniciar() async {
    try {
      _camaras = await availableCameras();
    } on CameraException catch (error) {
      _asignarError(traducirErrorCamara(error.code));
      return;
    }
    if (_camaras.isEmpty) {
      _asignarError(const FalloMedios.camaraNoDisponible());
      return;
    }
    final trasera = _camaras.indexWhere(
      (camara) => camara.lensDirection == CameraLensDirection.back,
    );
    _indice = trasera >= 0 ? trasera : 0;
    await _abrir();
  }

  /// Pasa de la cámara trasera a la frontal o al revés.
  Future<void> cambiarCamara() async {
    if (!puedeCambiar || _cambiando) return;
    if (_controlador?.value.isRecordingVideo ?? false) return;
    _cambiando = true;
    notifyListeners();
    final direccionActual = _camaras[_indice].lensDirection;
    final opuesta = _camaras.indexWhere(
      (camara) => camara.lensDirection != direccionActual,
    );
    _indice = opuesta >= 0 ? opuesta : (_indice + 1) % _camaras.length;
    await _abrir();
    _cambiando = false;
    if (!_liberado) notifyListeners();
  }

  /// Libera la cámara al pasar la app a segundo plano.
  Future<void> pausar() async {
    final anterior = _controlador;
    _controlador = null;
    if (!_liberado) notifyListeners();
    await anterior?.dispose();
  }

  /// Vuelve a abrir la cámara al regresar a la app.
  Future<void> reanudar() async {
    if (_liberado || _controlador != null || _camaras.isEmpty) return;
    await _abrir();
  }

  Future<void> _abrir() async {
    await pausar();
    final nuevo = CameraController(
      _camaras[_indice],
      paraVideo ? ResolutionPreset.high : ResolutionPreset.veryHigh,
      enableAudio: paraVideo,
      videoBitrate: paraVideo ? LimitesMedios.bitrateVideo : null,
      audioBitrate: paraVideo ? LimitesMedios.bitrateAudioDeVideo : null,
    );
    try {
      await nuevo.initialize();
    } on CameraException catch (error) {
      await nuevo.dispose();
      _asignarError(traducirErrorCamara(error.code));
      return;
    }
    if (_liberado) {
      await nuevo.dispose();
      return;
    }
    _controlador = nuevo;
    _error = null;
    notifyListeners();
  }

  void _asignarError(FalloMedios fallo) {
    _error = fallo;
    if (!_liberado) notifyListeners();
  }

  /// Traduce los códigos de `CameraException` del plugin.
  static FalloMedios traducirErrorCamara(String codigo) => switch (codigo) {
        'CameraAccessDenied' ||
        'CameraAccessDeniedWithoutPrompt' ||
        'CameraAccessRestricted' ||
        'cameraPermission' =>
          const FalloMedios.permisoCamara(),
        'AudioAccessDenied' ||
        'AudioAccessDeniedWithoutPrompt' ||
        'AudioAccessRestricted' =>
          const FalloMedios.permisoMicrofono(),
        _ => const FalloMedios.capturaFallida(),
      };

  @override
  void dispose() {
    _liberado = true;
    final anterior = _controlador;
    _controlador = null;
    anterior?.dispose();
    super.dispose();
  }
}
