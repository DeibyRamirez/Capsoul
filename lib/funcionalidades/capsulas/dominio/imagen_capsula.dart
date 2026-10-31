/// Catalogo local de imagenes de capsula. Son assets propios de la app
/// (`assets/imagenes_capsula/`); en la BD solo se guarda la [clave]
/// (`capsulas.imagen_clave`), nunca la imagen.
enum ImagenCapsula {
  corazon('capsula_01', 'Corazon'),
  ninoGlobo('capsula_02', 'Nino con globo'),
  flores('capsula_03', 'Flores'),
  estrella('capsula_04', 'Estrella'),
  barcoOceano('capsula_05', 'Barco en el oceano'),
  desiertoCamellos('capsula_06', 'Desierto'),
  cabanaNieve('capsula_07', 'Cabana en la nieve'),
  engranajes('capsula_08', 'Engranajes'),
  puertaEgipcia('capsula_09', 'Puerta egipcia'),
  volcan('capsula_10', 'Volcan'),
  dirigibleNubes('capsula_11', 'Dirigible'),
  libros('capsula_12', 'Libros'),
  espacioPlanetas('capsula_13', 'Espacio'),
  castillo('capsula_14', 'Castillo'),
  dinosaurio('capsula_15', 'Dinosaurio'),
  arcoiris('capsula_16', 'Arcoiris');

  const ImagenCapsula(this.clave, this.nombre);

  /// Clave estable que se guarda en `capsulas.imagen_clave`. No cambiarla.
  final String clave;

  /// Texto accesible para lectores de pantalla.
  final String nombre;

  /// Ruta del asset WebP optimizado.
  String get ruta => 'assets/imagenes_capsula/$clave.webp';

  /// Imagen que se muestra si la capsula no tiene clave o es desconocida.
  static const ImagenCapsula porDefecto = ImagenCapsula.corazon;

  /// Imagen de [clave] o `null` si no existe en el catalogo.
  static ImagenCapsula? buscar(String? clave) {
    if (clave == null) return null;
    for (final imagen in values) {
      if (imagen.clave == clave) return imagen;
    }
    return null;
  }

  /// Imagen de [clave] o [porDefecto].
  static ImagenCapsula desdeClave(String? clave) =>
      buscar(clave) ?? porDefecto;
}
