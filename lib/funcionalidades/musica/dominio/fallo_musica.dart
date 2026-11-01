/// Tipos de error del catálogo de música (API pública de Deezer).
enum TipoFalloMusica {
  sinConexion,
  tiempoAgotado,
  limiteSolicitudes,
  servicio,
  respuestaInvalida,
  noEncontrada,
  sinPreview,
}

/// Error tipado de música con mensaje en español para la UI.
class FalloMusica implements Exception {
  const FalloMusica(this.tipo);

  final TipoFalloMusica tipo;

  String get mensaje => switch (tipo) {
        TipoFalloMusica.sinConexion =>
          'Sin conexión. Revisa tu internet e intenta de nuevo.',
        TipoFalloMusica.tiempoAgotado =>
          'Deezer tardó demasiado en responder. Intenta de nuevo.',
        TipoFalloMusica.limiteSolicitudes =>
          'Demasiadas búsquedas seguidas. Espera un momento.',
        TipoFalloMusica.servicio =>
          'Deezer no está disponible ahora. Intenta más tarde.',
        TipoFalloMusica.respuestaInvalida =>
          'No pudimos leer la respuesta de Deezer.',
        TipoFalloMusica.noEncontrada => 'La canción ya no está en Deezer.',
        TipoFalloMusica.sinPreview =>
          'Esta canción no tiene vista previa de 30 s.',
      };

  @override
  String toString() => 'FalloMusica(${tipo.name})';
}
