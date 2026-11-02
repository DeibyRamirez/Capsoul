import 'condicion_herencia.dart';
import 'grupo_legado_beneficiario.dart';
import 'herencia.dart';
import 'herencia_recibida.dart';
import 'metadatos_herencia.dart';

/// Operaciones de Mi legado (ver `docs/contrato-api-legado.md`).
abstract interface class RepositorioLegado {
  Future<ResumenLegado> obtenerResumen();

  Future<List<GrupoLegadoBeneficiario>> listarAgrupadoPorBeneficiario();

  Future<List<Herencia>> listarPorBeneficiario(String beneficiarioUsuarioId);

  Future<DetalleHerencia> obtenerDetalle(String herenciaId);

  Future<String> crearHerencia({
    required String titulo,
    String? descripcion,
    required String beneficiarioUsuarioId,
    required CondicionHerencia condicion,
    MetadatosHerencia metadatos = const MetadatosHerencia(),
    DateTime? fechaActivacion,
    int? diasInactividad,
    bool activar = false,
  });

  Future<void> actualizarHerencia({
    required String herenciaId,
    String? titulo,
    String? descripcion,
    MetadatosHerencia? metadatos,
    bool? activar,
  });

  Future<void> vincularElementos(String herenciaId, List<String> elementoIds);

  Future<void> vincularCapsula(String herenciaId, String capsulaId);

  Future<void> establecerPersonaConfianza(String nombreUsuario);

  Future<void> quitarPersonaConfianza();

  Future<void> guardarInstrucciones(String? texto);

  Future<String?> leerInstrucciones();

  Future<String?> leerPersonaConfianzaId();

  Future<void> solicitarRespaldoLegal(String herenciaId);

  Future<List<HerenciaRecibida>> listarRecibidas();

  Future<List<HerenciaPorConfirmar>> listarPorConfirmar();

  Future<void> confirmarHerencia(String herenciaId);

  Future<void> actualizarHerenciaSellada({
    required String herenciaId,
    required String titulo,
    String? descripcion,
    required MetadatosHerencia metadatos,
    DateTime? fechaActivacion,
  });
}
