import '../dominio/condicion_herencia.dart';
import '../dominio/fallo_legado.dart';
import '../dominio/grupo_legado_beneficiario.dart';
import '../dominio/herencia.dart';
import '../dominio/metadatos_herencia.dart';
import '../dominio/repositorio_legado.dart';

/// Implementación VPS (ver `docs/contrato-api-legado.md`). Pendiente de backend HTTP.
class RepositorioLegadoHttp implements RepositorioLegado {
  const RepositorioLegadoHttp();

  Never _noDisponible() => throw const FalloLegado(
        FalloLegado.codigoDesconocido,
        'Legado por API VPS aún no está disponible.',
      );

  @override
  Future<ResumenLegado> obtenerResumen() async => _noDisponible();

  @override
  Future<List<GrupoLegadoBeneficiario>> listarAgrupadoPorBeneficiario() async =>
      _noDisponible();

  @override
  Future<List<Herencia>> listarPorBeneficiario(String beneficiarioUsuarioId) async =>
      _noDisponible();

  @override
  Future<DetalleHerencia> obtenerDetalle(String herenciaId) async => _noDisponible();

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
      _noDisponible();

  @override
  Future<void> actualizarHerencia({
    required String herenciaId,
    String? titulo,
    String? descripcion,
    MetadatosHerencia? metadatos,
    bool? activar,
  }) async =>
      _noDisponible();

  @override
  Future<void> vincularElementos(String herenciaId, List<String> elementoIds) async =>
      _noDisponible();

  @override
  Future<void> vincularCapsula(String herenciaId, String capsulaId) async =>
      _noDisponible();

  @override
  Future<void> establecerPersonaConfianza(String nombreUsuario) async => _noDisponible();

  @override
  Future<void> quitarPersonaConfianza() async => _noDisponible();

  @override
  Future<void> guardarInstrucciones(String? texto) async => _noDisponible();

  @override
  Future<String?> leerInstrucciones() async => _noDisponible();

  @override
  Future<String?> leerPersonaConfianzaId() async => _noDisponible();

  @override
  Future<void> solicitarRespaldoLegal(String herenciaId) async => _noDisponible();
}
