import 'package:capsoul/funcionalidades/autenticacion/aplicacion/proveedores_autenticacion.dart';
import 'package:capsoul/funcionalidades/capsulas/aplicacion/proveedores_capsulas.dart';
import 'package:capsoul/funcionalidades/legado/aplicacion/proveedores_legado.dart';
import 'package:capsoul/funcionalidades/legado/dominio/condicion_herencia.dart';
import 'package:capsoul/funcionalidades/legado/dominio/estado_herencia.dart';
import 'package:capsoul/funcionalidades/legado/dominio/grupo_legado_beneficiario.dart';
import 'package:capsoul/funcionalidades/legado/dominio/herencia.dart';
import 'package:capsoul/funcionalidades/legado/dominio/herencia_recibida.dart';
import 'package:capsoul/funcionalidades/legado/dominio/metadatos_herencia.dart';
import 'package:capsoul/funcionalidades/legado/dominio/repositorio_legado.dart';
import 'package:capsoul/funcionalidades/legado/presentacion/pantalla_detalle_herencia.dart';
import 'package:capsoul/nucleo/tema/tema_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _RepoDetalle implements RepositorioLegado {
  _RepoDetalle(this.detalle);

  final DetalleHerencia detalle;

  @override
  Future<DetalleHerencia> obtenerDetalle(String id) async => detalle;

  @override
  Future<ResumenLegado> obtenerResumen() async =>
      const ResumenLegado(herenciasActivas: 0, tieneInstrucciones: false);

  @override
  Future<List<GrupoLegadoBeneficiario>> listarAgrupadoPorBeneficiario() async =>
      const [];

  @override
  Future<List<Herencia>> listarPorBeneficiario(String id) async => const [];

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
      'x';

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
}

void main() {
  testWidgets('detalle liberada no ofrece editar', (tester) async {
    final detalle = DetalleHerencia(
      herencia: Herencia(
        id: 'h1',
        titulo: 'Reloj',
        estado: EstadoHerencia.liberada,
        condicionActivacion: CondicionHerencia.fecha,
        fechaActivacion: DateTime(2026, 10, 1),
        propietarioId: 'u1',
        beneficiarioUsuarioId: 'u3',
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          proveedorRepositorioLegado.overrideWithValue(_RepoDetalle(detalle)),
          proveedorReloj.overrideWithValue(() => DateTime(2026, 11, 2)),
          proveedorEstadoAutenticacion.overrideWith(
            (ref) => Stream.value(null),
          ),
        ],
        child: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            theme: TemaApp.claro,
            home: const PantallaDetalleHerencia(herenciaId: 'h1'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Reloj'), findsWidgets);
    expect(find.text('Editar información'), findsNothing);
  });
}
