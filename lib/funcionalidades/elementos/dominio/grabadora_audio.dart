/// Grabadora de audio del teléfono (detrás de una interfaz para probar la
/// pantalla sin el plugin).
abstract interface class GrabadoraAudio {
  /// Pide el permiso del micrófono si hace falta. `true` si está concedido.
  Future<bool> tienePermiso();

  /// Empieza a grabar en un archivo temporal con la configuración de
  /// [LimitesMedios].
  Future<void> iniciar();

  /// Detiene la grabación y devuelve la ruta del archivo (o `null`).
  Future<String?> detener();

  /// Descarta la grabación en curso.
  Future<void> cancelar();

  /// Niveles normalizados 0..1 mientras se graba.
  Stream<double> niveles();

  Future<void> liberar();
}
