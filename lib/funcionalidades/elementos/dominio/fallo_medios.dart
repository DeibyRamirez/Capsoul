import '../../../nucleo/errores/fallo_app.dart';

/// Fallo al capturar, comprimir, validar o subir un elemento, con mensaje
/// en español para el usuario.
class FalloMedios implements FalloApp {
  const FalloMedios(this.codigo, this.mensaje);

  const FalloMedios.permisoCamara()
      : this(
          codigoPermisoCamara,
          'Capsoul necesita permiso para usar la cámara. Actívalo en los '
              'ajustes del teléfono.',
        );

  const FalloMedios.permisoMicrofono()
      : this(
          codigoPermisoMicrofono,
          'Capsoul necesita permiso para usar el micrófono. Actívalo en los '
              'ajustes del teléfono.',
        );

  const FalloMedios.camaraNoDisponible()
      : this(codigoCamaraNoDisponible,
            'No encontramos una cámara disponible en este teléfono.');

  const FalloMedios.capturaFallida()
      : this(codigoCapturaFallida,
            'No pudimos completar la captura. Inténtalo de nuevo.');

  const FalloMedios.compresionFallida()
      : this(codigoCompresionFallida,
            'No pudimos preparar el archivo. Inténtalo de nuevo.');

  const FalloMedios.subidaNoDisponible()
      : this(
          codigoSubidaNoDisponible,
          'La subida de fotos, videos y audios aún no está disponible. '
              'Por ahora puedes guardar notas de texto.',
        );

  const FalloMedios.cuotaExcedida()
      : this(
          codigoCuotaExcedida,
          'Llegaste al límite de 200 MB de recuerdos. Libera espacio para '
              'guardar más.',
        );

  const FalloMedios.subidaFallida()
      : this(codigoSubidaFallida,
            'No pudimos subir el archivo. Revisa tu conexión e inténtalo de '
                'nuevo.');

  const FalloMedios.sinRed()
      : this(codigoSinRed,
            'Sin conexión. Revisa tu internet e inténtalo de nuevo.');

  static const String codigoExcedeTamano = 'excede_tamano';
  static const String codigoExcedeDuracion = 'excede_duracion';
  static const String codigoNotaVacia = 'nota_vacia';
  static const String codigoNotaLarga = 'nota_larga';
  static const String codigoPermisoCamara = 'permiso_camara';
  static const String codigoPermisoMicrofono = 'permiso_microfono';
  static const String codigoCamaraNoDisponible = 'camara_no_disponible';
  static const String codigoCapturaFallida = 'captura_fallida';
  static const String codigoCompresionFallida = 'compresion_fallida';
  static const String codigoSubidaNoDisponible = 'subida_no_disponible';
  static const String codigoCuotaExcedida = 'cuota_excedida';
  static const String codigoSubidaFallida = 'subida_fallida';
  static const String codigoSinRed = 'sin_red';

  @override
  final String codigo;

  @override
  final String mensaje;

  @override
  String toString() => 'FalloMedios($codigo): $mensaje';
}
