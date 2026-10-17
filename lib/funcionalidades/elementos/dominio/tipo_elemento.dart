/// Tipos de elemento base de Capsoul. [valorBd] coincide con el enum
/// `public.tipo_elemento` de la migración 000001.
enum TipoElemento {
  foto('foto', 'Foto'),
  video('video', 'Video'),
  audio('audio', 'Nota de voz'),
  musica('musica', 'Música'),
  texto('texto', 'Nota');

  const TipoElemento(this.valorBd, this.etiqueta);

  /// Valor guardado en la columna `elementos.tipo`.
  final String valorBd;

  /// Nombre para mostrar en la UI.
  final String etiqueta;

  /// Tipo de recurso de Cloudinary (`image`/`video`); el audio se sube como
  /// `video`. `null` para las notas, que no van a Cloudinary.
  String? get tipoRecursoCloudinary => switch (this) {
        TipoElemento.foto => 'image',
        TipoElemento.video || TipoElemento.audio => 'video',
        TipoElemento.texto || TipoElemento.musica => null,
      };

  bool get esMedio => this != TipoElemento.texto;

  /// Usa Cloudinary (subida firmada), no aplica a notas ni música de catálogo.
  bool get usaCloudinary => this != TipoElemento.texto && this != TipoElemento.musica;

  /// Devuelve el tipo de [valor] o `null` si no se reconoce (falla cerrado).
  static TipoElemento? desdeValorBd(Object? valor) {
    for (final tipo in TipoElemento.values) {
      if (tipo.valorBd == valor) return tipo;
    }
    return null;
  }
}
