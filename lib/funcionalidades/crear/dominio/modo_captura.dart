/// Modo activo en el hub de creación (cámara a pantalla completa).
enum ModoCaptura {
  foto,
  video,
  texto,
}

extension ModoCapturaEtiqueta on ModoCaptura {
  String get etiqueta => switch (this) {
        ModoCaptura.foto => 'Foto',
        ModoCaptura.video => 'Video',
        ModoCaptura.texto => 'Texto',
      };
}
