import '../../../nucleo/errores/fallo_app.dart';

class FalloAmistad implements FalloApp {
  const FalloAmistad(this.codigo, this.mensaje);

  const FalloAmistad.sinSesion()
      : this('sin_sesion', 'Inicia sesión para continuar.');

  const FalloAmistad.invitacionInvalida()
      : this(
          'invitacion_invalida',
          'Este enlace de invitación no es válido o ya expiró.',
        );

  const FalloAmistad.permisoDenegado()
      : this('permiso_denegado', 'No puedes realizar esta acción.');

  const FalloAmistad.desconocido()
      : this('desconocido', 'No pudimos completar la acción. Intenta de nuevo.');

  const FalloAmistad.usuarioNoEncontrado()
      : this('usuario_no_encontrado', 'No hay ningún usuario con ese @.');

  const FalloAmistad.yaSonAmigos()
      : this('ya_son_amigos', 'Ya son amigos.');

  const FalloAmistad.solicitudPendiente()
      : this('solicitud_pendiente', 'Ya hay una solicitud pendiente entre ustedes.');

  const FalloAmistad.receptorInvalido()
      : this('receptor_invalido', 'No puedes enviarte una solicitud a ti mismo.');

  @override
  final String codigo;

  @override
  final String mensaje;
}
