import 'package:capsoul/funcionalidades/legado/aplicacion/controlador_nueva_herencia.dart';
import 'package:capsoul/funcionalidades/legado/aplicacion/proveedores_legado.dart';
import 'package:capsoul/funcionalidades/legado/dominio/acceso_herencia.dart';
import 'package:capsoul/funcionalidades/legado/dominio/condicion_herencia.dart';
import 'package:capsoul/funcionalidades/legado/dominio/fallo_legado.dart';
import 'package:capsoul/funcionalidades/legado/dominio/grupo_legado_beneficiario.dart';
import 'package:capsoul/funcionalidades/legado/dominio/herencia.dart';
import 'package:capsoul/funcionalidades/legado/dominio/herencia_recibida.dart';
import 'package:capsoul/funcionalidades/legado/dominio/metadatos_herencia.dart';
import 'package:capsoul/funcionalidades/legado/dominio/repositorio_legado.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _RepoFalso implements RepositorioLegado {
  String? confianzaId = 'confianza-1';

  @override
  Future<String?> leerPersonaConfianzaId() async => confianzaId;

  @override
  Future<ResumenLegado> obtenerResumen() async =>
      const ResumenLegado(herenciasActivas: 0, tieneInstrucciones: false);

  @override
  Future<List<GrupoLegadoBeneficiario>> listarAgrupadoPorBeneficiario() async =>
      const [];

  @override
  Future<List<Herencia>> listarPorBeneficiario(String id) async => const [];

  @override
  Future<DetalleHerencia> obtenerDetalle(String id) async =>
      throw UnimplementedError();

  @override
  Future<String> crearHerencia({
    required String titulo,
    String? descripcion,
    required String beneficiarioUsuarioId,
    required CondicionHerencia condicion,
    MetadatosHerencia metadatos = const MetadatosHerencia(),
    DateTime? fechaActivacion,
    int? diasInactividad,
    String? personaConfianzaUsuarioId,
    bool activar = false,
  }) async =>
      'h1';

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
  Future<void> vincularCapsula(String herenciaId, String capsulaId) async {}

  @override
  Future<void> establecerPersonaConfianza(String n) async {}

  @override
  Future<void> quitarPersonaConfianza() async {}

  @override
  Future<void> guardarInstrucciones(String? t) async {}

  @override
  Future<String?> leerInstrucciones() async => null;

  @override
  Future<void> solicitarRespaldoLegal(String id) async {}

  @override
  Future<List<HerenciaRecibida>> listarRecibidas() async => const [];

  @override
  Future<List<HerenciaPorConfirmar>> listarPorConfirmar() async => const [];

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

  @override
  Future<void> actualizarPersonaConfianzaHerencia(
    String herenciaId,
    String personaConfianzaUsuarioId,
  ) async {}

  @override
  Future<List<HerenciaACuidado>> listarACuidado() async => const [];

  @override
  Future<EstadoAccesoHerencia> obtenerEstadoAcceso(String herenciaId) async =>
      const EstadoAccesoHerencia();

  @override
  Future<ResultadoValidacionCodigo> validarCodigoHerencia(
    String herenciaId,
    String codigo,
  ) async =>
      const ResultadoValidacionCodigo(ok: true);

  @override
  Future<void> solicitarCodigoHerencia(String herenciaId) async {}
}

void main() {
  late ProviderContainer contenedor;
  late _RepoFalso repo;

  setUp(() {
    repo = _RepoFalso();
    contenedor = ProviderContainer(
      overrides: [proveedorRepositorioLegado.overrideWithValue(repo)],
    );
    addTearDown(contenedor.dispose);
  });

  test('el valor aproximado es obligatorio y numérico', () async {
    final ctrl = contenedor.read(proveedorControladorNuevaHerencia.notifier);
    ctrl.actualizar(
      const BorradorNuevaHerencia(
        paso: 3,
        tipoActivo: 'CDT',
        titular: 'Ana',
        valorAproximado: 'abc',
        instrucciones: 'banco',
      ),
    );
    expect(
      () => ctrl.validarPasoActual(),
      throwsA(isA<FalloLegado>()),
    );
    ctrl.actualizar(
      const BorradorNuevaHerencia(
        paso: 3,
        tipoActivo: 'CDT',
        titular: 'Ana',
        valorAproximado: '1.250.000',
        instrucciones: 'banco',
      ),
    );
    await ctrl.validarPasoActual();
  });

  test('fecha programada exige un día futuro', () async {
    final ctrl = contenedor.read(proveedorControladorNuevaHerencia.notifier);
    ctrl.actualizar(
      const BorradorNuevaHerencia(
        paso: 4,
        condicion: CondicionHerencia.fecha,
      ),
    );
    expect(
      () => ctrl.validarPasoActual(),
      throwsA(isA<FalloLegado>()),
    );
  });

  test('confirmación acepta la persona de confianza elegida para la herencia',
      () async {
    repo.confianzaId = null;
    final ctrl = contenedor.read(proveedorControladorNuevaHerencia.notifier);
    ctrl.actualizar(
      const BorradorNuevaHerencia(
        paso: 4,
        condicion: CondicionHerencia.confirmacionConfianza,
        beneficiarioUsuarioId: 'benef-1',
        personaConfianzaUsuarioId: 'confianza-1',
      ),
    );
    await ctrl.validarCondicionActivacion();
  });

  test('la persona de confianza no puede ser el beneficiario', () async {
    final ctrl = contenedor.read(proveedorControladorNuevaHerencia.notifier);
    ctrl.actualizar(
      const BorradorNuevaHerencia(
        paso: 4,
        condicion: CondicionHerencia.confirmacionConfianza,
        beneficiarioUsuarioId: 'misma-persona',
        personaConfianzaUsuarioId: 'misma-persona',
      ),
    );
    expect(
      () => ctrl.validarCondicionActivacion(),
      throwsA(
        isA<FalloLegado>().having(
          (e) => e.codigo,
          'codigo',
          FalloLegado.codigoConfianzaNoBeneficiario,
        ),
      ),
    );
  });
}
