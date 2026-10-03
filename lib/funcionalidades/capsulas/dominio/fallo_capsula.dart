import '../../../nucleo/errores/fallo_app.dart';

/// Fallo de dominio de las cápsulas, con mensaje en español.
class FalloCapsula implements FalloApp {
  const FalloCapsula(this.codigo, this.mensaje);

  const FalloCapsula.tituloInvalido()
      : this(codigoTituloInvalido,
            'Escribe para quién es la cápsula (de 1 a 120 caracteres).');

  const FalloCapsula.fechaInvalida()
      : this(codigoFechaInvalida,
            'Elige una fecha de apertura en el futuro.');

  const FalloCapsula.sinElementos()
      : this(codigoSinElementos,
            'Agrega al menos un recuerdo: foto, video, nota de voz o nota.');

  const FalloCapsula.demasiadosElementos()
      : this(codigoDemasiadosElementos,
            'Una cápsula puede tener como máximo 10 recuerdos.');

  const FalloCapsula.permisoDenegado()
      : this(codigoPermisoDenegado,
            'No tienes permiso para crear o editar esta cápsula.');

  const FalloCapsula.permisoRecuerdo()
      : this(codigoPermisoRecuerdo,
            'No tienes permiso para guardar o cambiar este recuerdo.');

  const FalloCapsula.permisoEnlace()
      : this(codigoPermisoEnlace,
            'No puedes agregar ese recuerdo a esta cápsula.');

  const FalloCapsula.sesionVencida()
      : this(codigoSesionVencida,
            'Tu sesión expiró. Vuelve a iniciar sesión.');

  const FalloCapsula.sinSesion()
      : this(codigoSinSesion, 'Inicia sesión para guardar tu cápsula.');

  const FalloCapsula.sinRed()
      : this(codigoSinRed,
            'Sin conexión. Revisa tu internet e inténtalo de nuevo.');

  const FalloCapsula.desconocido()
      : this(codigoDesconocido, kMensajeErrorInesperado);

  static const String codigoTituloInvalido = 'titulo_invalido';
  static const String codigoFechaInvalida = 'fecha_invalida';
  static const String codigoSinElementos = 'sin_elementos';
  static const String codigoDemasiadosElementos = 'demasiados_elementos';
  static const String codigoPermisoDenegado = 'permiso_denegado';
  static const String codigoPermisoRecuerdo = 'permiso_recuerdo';
  static const String codigoPermisoEnlace = 'permiso_enlace';
  static const String codigoSesionVencida = 'sesion_vencida';
  static const String codigoSinSesion = 'sin_sesion';
  static const String codigoSinRed = 'sin_red';
  static const String codigoDesconocido = 'desconocido';

  @override
  final String codigo;

  @override
  final String mensaje;

  @override
  String toString() => 'FalloCapsula($codigo): $mensaje';
}
