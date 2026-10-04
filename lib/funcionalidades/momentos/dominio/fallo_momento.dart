import '../../../nucleo/errores/fallo_app.dart';

/// Fallo de dominio de los momentos, con mensaje en español.
class FalloMomento implements FalloApp {
  const FalloMomento(this.codigo, this.mensaje);

  const FalloMomento.tituloInvalido()
      : this(codigoTituloInvalido,
            'Ponle un nombre al momento (de 1 a 80 caracteres).');

  const FalloMomento.descripcionLarga()
      : this(codigoDescripcionLarga,
            'La descripción puede tener hasta 500 caracteres.');

  const FalloMomento.sinRecuerdos()
      : this(codigoSinRecuerdos, 'Agrega al menos un recuerdo al momento.');

  const FalloMomento.demasiadosRecuerdos()
      : this(codigoDemasiadosRecuerdos,
            'Un momento puede tener como máximo 60 recuerdos.');

  const FalloMomento.portadaInvalida()
      : this(codigoPortadaInvalida,
            'La portada debe ser una foto o un video del momento.');

  const FalloMomento.permisoDenegado()
      : this(codigoPermisoDenegado,
            'No tienes permiso para crear o cambiar este momento.');

  const FalloMomento.sinSesion()
      : this(codigoSinSesion, 'Inicia sesión para crear momentos.');

  const FalloMomento.sesionVencida()
      : this(codigoSesionVencida,
            'Tu sesión expiró. Vuelve a iniciar sesión.');

  const FalloMomento.sinRed()
      : this(codigoSinRed,
            'Sin conexión. Revisa tu internet e inténtalo de nuevo.');

  const FalloMomento.desconocido()
      : this(codigoDesconocido, kMensajeErrorInesperado);

  static const String codigoTituloInvalido = 'titulo_invalido';
  static const String codigoDescripcionLarga = 'descripcion_larga';
  static const String codigoSinRecuerdos = 'sin_recuerdos';
  static const String codigoDemasiadosRecuerdos = 'demasiados_recuerdos';
  static const String codigoPortadaInvalida = 'portada_invalida';
  static const String codigoPermisoDenegado = 'permiso_denegado';
  static const String codigoSinSesion = 'sin_sesion';
  static const String codigoSesionVencida = 'sesion_vencida';
  static const String codigoSinRed = 'sin_red';
  static const String codigoDesconocido = 'desconocido';

  @override
  final String codigo;

  @override
  final String mensaje;

  @override
  String toString() => 'FalloMomento($codigo)';
}
