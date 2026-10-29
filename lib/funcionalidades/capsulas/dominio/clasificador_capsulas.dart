import 'capsula.dart';
import 'capsula_recibida.dart';

/// La cápsula es solo para quien la creó.
///
/// En `capsula_destinatarios`, «para mí mismo» es el autor como único
/// destinatario: un `usuario_id` igual a `autor_id` y ningún correo externo.
/// Si el autor se incluye junto con otra persona, la cápsula se envió y va
/// a «Mis cápsulas», sin repetirse en las dos pestañas.
bool capsulaEsSoloParaSuAutor(Capsula capsula) {
  if (capsula.tieneCorreoExterno) return false;
  final ids = capsula.destinatariosUsuarioIds;
  return ids.length == 1 && ids.single == capsula.autorId;
}

/// Cápsulas del autor que no son exclusivamente para él.
List<Capsula> capsulasEnviadas(List<Capsula> lista) => [
      for (final capsula in lista)
        if (!capsulaEsSoloParaSuAutor(capsula)) capsula,
    ];

/// Cápsulas del autor cuyo único destinatario es él mismo.
List<Capsula> capsulasParaMiMismo(List<Capsula> lista) => [
      for (final capsula in lista)
        if (capsulaEsSoloParaSuAutor(capsula)) capsula,
    ];

/// «Para mí» son las que envió otra persona.
///
/// `capsulas_recibidas()` también devuelve las propias si el autor figura
/// como destinatario. Esas no se repiten aquí: ya están en el listado del autor.
List<CapsulaRecibida> recibidasDeOtrasPersonas(
  List<CapsulaRecibida> lista,
  String? uid,
) =>
    [
      for (final recibida in lista)
        if (uid == null || recibida.autorId != uid) recibida,
    ];
