import 'package:capsoul/funcionalidades/legado/dominio/condicion_herencia.dart';
import 'package:capsoul/funcionalidades/legado/dominio/grupo_legado_beneficiario.dart';
import 'package:capsoul/funcionalidades/legado/dominio/herencia.dart';
import 'package:capsoul/funcionalidades/legado/dominio/herencia_recibida.dart';
import 'package:capsoul/funcionalidades/legado/dominio/metadatos_herencia.dart';
import 'package:capsoul/funcionalidades/legado/dominio/repositorio_legado.dart';

class RepositorioLegadoFalso implements RepositorioLegado {
  final grupos = <GrupoLegadoBeneficiario>[];
  final recibidas = <HerenciaRecibida>[];
  final porConfirmar = <HerenciaPorConfirmar>[];

  @override
  Future<ResumenLegado> obtenerResumen() async =>
      const ResumenLegado(herenciasActivas: 0, tieneInstrucciones: false);

  @override
  Future<List<GrupoLegadoBeneficiario>> listarAgrupadoPorBeneficiario() async =>
      List.of(grupos);

  @override
  Future<List<Herencia>> listarPorBeneficiario(String id) async => const [];

  @override
  Future<DetalleHerencia> obtenerDetalle(String id) async {
    throw const FormatException('herencia_invalida');
  }

  @override
  Future<String> crearHerencia({
    required String titulo,
    String? descripcion,
    required String beneficiarioUsuarioId,
    required CondicionHerencia condicion,
    MetadatosHerencia metadatos = const MetadatosHerencia(),
    DateTime? fechaActivacion,
    int? diasInactividad,
    bool activar = false,
  }) async =>
      'h-falso';

  @override
  Future<void> actualizarHerencia({
    required String herenciaId,
    String? titulo,
    String? descripcion,
    MetadatosHerencia? metadatos,
    bool? activar,
  }) async {}

  @override
  Future<void> vincularElementos(String id, List<String> ids) async {}

  @override
  Future<void> vincularCapsula(String a, String b) async {}

  @override
  Future<void> establecerPersonaConfianza(String n) async {}

  @override
  Future<void> quitarPersonaConfianza() async {}

  @override
  Future<void> guardarInstrucciones(String? t) async {}

  @override
  Future<String?> leerInstrucciones() async => null;

  @override
  Future<String?> leerPersonaConfianzaId() async => null;

  @override
  Future<void> solicitarRespaldoLegal(String id) async {}

  @override
  Future<List<HerenciaRecibida>> listarRecibidas() async => List.of(recibidas);

  @override
  Future<List<HerenciaPorConfirmar>> listarPorConfirmar() async =>
      List.of(porConfirmar);

  @override
  Future<void> confirmarHerencia(String id) async {}

  @override
  Future<void> actualizarHerenciaSellada({
    required String herenciaId,
    required String titulo,
    String? descripcion,
    required MetadatosHerencia metadatos,
    DateTime? fechaActivacion,
  }) async {}
}
