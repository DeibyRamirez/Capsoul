import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/infraestructura/configuracion_backend.dart';
import '../../../nucleo/infraestructura/proveedores_infraestructura.dart';
import '../../autenticacion/aplicacion/proveedores_autenticacion.dart';
import '../datos/repositorio_legado_http.dart';
import '../datos/repositorio_legado_supabase.dart';
import '../dominio/grupo_legado_beneficiario.dart';
import '../dominio/herencia.dart';
import '../dominio/herencia_recibida.dart';
import '../dominio/repositorio_legado.dart';

final proveedorRepositorioLegado = Provider<RepositorioLegado>((ref) {
  if (ConfiguracionBackend.esVps) {
    return const RepositorioLegadoHttp();
  }
  final uid = ref.watch(
    proveedorEstadoAutenticacion.select((e) => e.value?.uid),
  );
  return RepositorioLegadoSupabase(
    cliente: ref.watch(proveedorClientePostgrest),
    uidActual: () => uid,
  );
});

final proveedorResumenLegado = FutureProvider.autoDispose<ResumenLegado>((ref) {
  return ref.watch(proveedorRepositorioLegado).obtenerResumen();
});

final proveedorGruposLegadoBeneficiario =
    FutureProvider.autoDispose<List<GrupoLegadoBeneficiario>>((ref) {
  return ref.watch(proveedorRepositorioLegado).listarAgrupadoPorBeneficiario();
});

final proveedorPersonaConfianzaLegadoId =
    FutureProvider.autoDispose<String?>((ref) {
  return ref.watch(proveedorRepositorioLegado).leerPersonaConfianzaId();
});

final proveedorInstruccionesLegado = FutureProvider.autoDispose<String?>((ref) {
  return ref.watch(proveedorRepositorioLegado).leerInstrucciones();
});

final proveedorDetalleHerencia =
    FutureProvider.autoDispose.family<DetalleHerencia, String>((ref, id) {
  return ref.watch(proveedorRepositorioLegado).obtenerDetalle(id);
});

final proveedorHerenciasRecibidas =
    FutureProvider.autoDispose<List<HerenciaRecibida>>((ref) {
  return ref.watch(proveedorRepositorioLegado).listarRecibidas();
});

final proveedorHerenciasPorConfirmar =
    FutureProvider.autoDispose<List<HerenciaPorConfirmar>>((ref) {
  return ref.watch(proveedorRepositorioLegado).listarPorConfirmar();
});

enum BandejaLegado { creadas, recibidas }

class ControladorBandejaLegado extends Notifier<BandejaLegado> {
  @override
  BandejaLegado build() => BandejaLegado.creadas;

  void elegir(BandejaLegado bandeja) => state = bandeja;
}

final proveedorBandejaLegado =
    NotifierProvider<ControladorBandejaLegado, BandejaLegado>(
  ControladorBandejaLegado.new,
);
