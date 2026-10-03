import '../../../nucleo/errores/fallo_app.dart';

/// Fallo de dominio del banco de recuerdos, con mensaje en español.
class FalloRecuerdo implements FalloApp {
  const FalloRecuerdo(this.codigo, this.mensaje);

  const FalloRecuerdo.tituloInvalido()
      : this(codigoTituloInvalido,
            'El título puede tener hasta 120 caracteres.');

  const FalloRecuerdo.fechaInvalida()
      : this(codigoFechaInvalida,
            'La fecha del recuerdo no puede estar en el futuro.');

  const FalloRecuerdo.enCapsulaSellada()
      : this(
          codigoEnCapsulaSellada,
          'Este recuerdo está en una cápsula programada o abierta, por eso no '
              'se puede borrar.',
        );

  const FalloRecuerdo.permisoDenegado()
      : this(codigoPermisoDenegado,
            'No tienes permiso para guardar o cambiar este recuerdo.');

  const FalloRecuerdo.datoInvalido()
      : this(codigoDatoInvalido,
            'El recuerdo no cumple los límites permitidos.');

  const FalloRecuerdo.sinSesion()
      : this(codigoSinSesion, 'Inicia sesión para guardar tus recuerdos.');

  const FalloRecuerdo.sesionVencida()
      : this(codigoSesionVencida,
            'Tu sesión expiró. Vuelve a iniciar sesión.');

  const FalloRecuerdo.sinRed()
      : this(codigoSinRed,
            'Sin conexión. Revisa tu internet e inténtalo de nuevo.');

  const FalloRecuerdo.desconocido()
      : this(codigoDesconocido, kMensajeErrorInesperado);

  static const String codigoTituloInvalido = 'titulo_invalido';
  static const String codigoFechaInvalida = 'fecha_invalida';
  static const String codigoEnCapsulaSellada = 'en_capsula_sellada';
  static const String codigoPermisoDenegado = 'permiso_denegado';
  static const String codigoDatoInvalido = 'dato_invalido';
  static const String codigoSinSesion = 'sin_sesion';
  static const String codigoSesionVencida = 'sesion_vencida';
  static const String codigoSinRed = 'sin_red';
  static const String codigoDesconocido = 'desconocido';

  @override
  final String codigo;

  @override
  final String mensaje;

  @override
  String toString() => 'FalloRecuerdo($codigo): $mensaje';
}
