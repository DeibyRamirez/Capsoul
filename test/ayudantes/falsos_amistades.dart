import 'package:capsoul/funcionalidades/amistades/dominio/amigo.dart';
import 'package:capsoul/funcionalidades/amistades/dominio/repositorio_amistades.dart';
import 'package:capsoul/funcionalidades/amistades/dominio/usuario_resuelto.dart';

class RepositorioAmistadesFalso implements RepositorioAmistades {
  List<Amigo> amigos = [
    const Amigo(
      usuarioId: 'amigo-1',
      nombreVisible: 'Jacobo',
      nombreUsuario: 'jacobo',
    ),
  ];

  @override
  Future<List<Amigo>> listarAmigos() async => amigos;

  @override
  Future<List<SolicitudAmistad>> listarSolicitudesPendientes() async => [];

  @override
  Future<void> aceptarSolicitud(String amistadId) async {}

  @override
  Future<void> rechazarSolicitud(String amistadId) async {}

  @override
  Future<String> crearInvitacionEnlace() async => 'token-falso';

  @override
  Future<void> aceptarInvitacion(String token) async {}

  UsuarioResuelto? siguienteResuelto;

  @override
  Future<UsuarioResuelto?> resolverPorArroba(String arroba) async =>
      siguienteResuelto;

  @override
  Future<void> enviarSolicitudAmistad(String receptorUsuarioId) async {}
}
