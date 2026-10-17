import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// Un solo reproductor de preview para la pantalla de búsqueda (evita solapes).
class PreviewMusicaCompartido extends ChangeNotifier {
  PreviewMusicaCompartido();

  final AudioPlayer _reproductor = AudioPlayer();
  String? _idActivo;

  String? get idActivo => _idActivo;

  AudioPlayer get reproductor => _reproductor;

  Future<void> pausarSiNoEs(String idExterno) async {
    if (_idActivo != null && _idActivo != idExterno) {
      await _reproductor.pause();
      _idActivo = null;
      notifyListeners();
    }
  }

  void marcarActivo(String idExterno) {
    _idActivo = idExterno;
    notifyListeners();
  }

  @override
  void dispose() {
    _reproductor.dispose();
    super.dispose();
  }
}
