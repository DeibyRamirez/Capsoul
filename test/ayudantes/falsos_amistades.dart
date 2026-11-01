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

  List<SolicitudAmistad> solicitudes = [];
  final aceptadas = <String>[];
  final rechazadas = <String>[];

  @override
  Future<List<Amigo>> listarAmigos() async => amigos;

  @override
  Future<List<SolicitudAmistad>> listarSolicitudesPendientes() async =>
      List<SolicitudAmistad>.of(solicitudes);

  @override
  Future<void> aceptarSolicitud(String amistadId) async {
    aceptadas.add(amistadId);
    solicitudes.removeWhere((solicitud) => solicitud.id == amistadId);
    amigos = [
      ...amigos,
      Amigo(
        usuarioId: 'aceptado-$amistadId',
        nombreVisible: 'Aceptado $amistadId',
      ),
    ];
  }

  @override
  Future<void> rechazarSolicitud(String amistadId) async {
    rechazadas.add(amistadId);
    solicitudes.removeWhere((solicitud) => solicitud.id == amistadId);
  }

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
