import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/infraestructura/proveedores_infraestructura.dart';
import '../../autenticacion/aplicacion/proveedores_autenticacion.dart';
import '../../capsulas/aplicacion/proveedores_capsulas.dart';
import '../../elementos/aplicacion/proveedores_elementos.dart';
import '../datos/acceso_tablas_recuerdos.dart';
import '../datos/archivos_medio_dispositivo.dart';
import '../datos/repositorio_recuerdos_supabase.dart';
import '../datos/repositorio_urls_medio_agrupado.dart';
import '../dominio/archivos_medio.dart';
import '../dominio/enlace_medio.dart';
import '../dominio/filtro_recuerdos.dart';
import '../dominio/recuerdo.dart';
import '../dominio/repositorio_recuerdos.dart';
import '../dominio/repositorio_urls_medio.dart';
import '../dominio/uso_medios.dart';
import 'cargador_medios.dart';

final proveedorRepositorioRecuerdos = Provider<RepositorioRecuerdos>((ref) {
  final autenticacion = ref.watch(proveedorRepositorioAutenticacion);
  return RepositorioRecuerdosSupabase(
    acceso: AccesoTablasRecuerdosPostgrest(ref.watch(proveedorClientePostgrest)),
    medios: ref.watch(proveedorRepositorioMedios),
    uidActual: () => autenticacion.usuarioActual?.uid,
    reloj: ref.watch(proveedorReloj),
  );
});

final proveedorRepositorioUrlsMedio = Provider<RepositorioUrlsMedio>((ref) {
  ref.watch(
    proveedorEstadoAutenticacion.select((estado) => estado.value?.uid),
  );
  final funciones = ref.watch(proveedorClienteFuncionesApi);
  return RepositorioUrlsMedioAgrupado(
    solicitar: (ids) => solicitarUrlsMedio(funciones, ids),
  );
});

final proveedorArchivosMedio = Provider<ArchivosMedio>((ref) {
  final archivos = ArchivosMedioDispositivo();
  ref.listen(
    proveedorEstadoAutenticacion.select((estado) => estado.value?.uid),
    (antes, ahora) {
      if (antes != null && antes != ahora) unawaited(archivos.vaciar());
    },
  );
  return archivos;
});

final proveedorCargadorMedios = Provider<CargadorMedios>(
  (ref) => CargadorMedios(
    urls: ref.watch(proveedorRepositorioUrlsMedio),
    archivos: ref.watch(proveedorArchivosMedio),
  ),
);

final proveedorArchivoMedio =
    FutureProvider.autoDispose.family<File?, SolicitudMedio>(
  (ref, solicitud) => ref.watch(proveedorCargadorMedios).archivo(solicitud),
);

SolicitudMedio? solicitudMedioDe(Recuerdo recuerdo, VarianteMedio variante) {
  final publicId = recuerdo.publicId;
  if (publicId == null) return null;
  if (variante == VarianteMedio.miniatura && !recuerdo.esVisual) return null;
  return (idRecuerdo: recuerdo.id, publicId: publicId, variante: variante);
}

final proveedorRecuerdos = FutureProvider.autoDispose
    .family<List<Recuerdo>, FiltroRecuerdos>(
  (ref, filtro) => ref.watch(proveedorRepositorioRecuerdos).listar(filtro),
);

final proveedorRecuerdo = FutureProvider.autoDispose.family<Recuerdo?, String>(
  (ref, id) => ref.watch(proveedorRepositorioRecuerdos).obtener(id),
);

final proveedorUsoMedios = FutureProvider.autoDispose<UsoMedios>(
  (ref) => ref.watch(proveedorRepositorioRecuerdos).leerUsoMedios(),
);

class ControladorFiltroRecuerdos extends Notifier<FiltroRecuerdos> {
  @override
  FiltroRecuerdos build() => FiltroRecuerdos.todos;

  void cambiar(FiltroRecuerdos filtro) => state = filtro;
}

final proveedorFiltroRecuerdos =
    NotifierProvider<ControladorFiltroRecuerdos, FiltroRecuerdos>(
  ControladorFiltroRecuerdos.new,
);
