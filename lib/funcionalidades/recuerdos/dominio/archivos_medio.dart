import 'dart:io';

/// Archivos de medios guardados en el dispositivo por clave estable
/// ([claveMedio]): una vez descargado, un medio no vuelve a pedirse a
/// Cloudinary mientras siga en la caché.
abstract interface class ArchivosMedio {
  /// Archivo guardado con [clave] o `null`.
  Future<File?> enCache(String clave);

  /// Descarga [url] y la guarda con [clave].
  Future<File> descargar(String url, String clave);

  /// Borra todos los medios guardados (al cerrar sesión o cambiar de cuenta).
  Future<void> vaciar();
}
