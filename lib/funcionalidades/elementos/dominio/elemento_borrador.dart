import 'tipo_elemento.dart';

/// Elemento capturado en el teléfono, ya comprimido y validado, que todavía
/// no se ha guardado en el servidor.
class ElementoBorrador {
  const ElementoBorrador({
    required this.idLocal,
    required this.tipo,
    this.rutaArchivo,
    this.texto,
    this.bytes = 0,
    this.duracion,
    this.ancho,
    this.alto,
    this.formato,
    this.muestrasOnda = const [],
  });

  /// Identificador solo local (clave estable en listas).
  final String idLocal;
  final TipoElemento tipo;

  /// Archivo local (foto, video o audio). `null` en las notas.
  final String? rutaArchivo;

  /// Texto de la nota. `null` en los medios.
  final String? texto;

  final int bytes;
  final Duration? duracion;
  final int? ancho;
  final int? alto;

  /// Extensión del archivo sin punto (`jpg`, `mp4`, `m4a`).
  final String? formato;

  /// Niveles 0..1 de la grabación de audio para dibujar la onda.
  final List<double> muestrasOnda;

  static int _contador = 0;

  /// Genera un identificador local único dentro de la sesión.
  static String nuevoIdLocal() {
    _contador++;
    return 'local-${DateTime.now().microsecondsSinceEpoch}-$_contador';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ElementoBorrador &&
          other.idLocal == idLocal &&
          other.tipo == tipo &&
          other.rutaArchivo == rutaArchivo &&
          other.texto == texto &&
          other.bytes == bytes &&
          other.duracion == duracion;

  @override
  int get hashCode =>
      Object.hash(idLocal, tipo, rutaArchivo, texto, bytes, duracion);

  @override
  String toString() => 'ElementoBorrador($idLocal, ${tipo.valorBd})';
}
