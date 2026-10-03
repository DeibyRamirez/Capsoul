import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// Repositorio del banco de recuerdos (se sobrescribe en pruebas).
final proveedorRepositorioRecuerdos = Provider<RepositorioRecuerdos>((ref) {
  final autenticacion = ref.watch(proveedorRepositorioAutenticacion);
  return RepositorioRecuerdosSupabase(
    acceso: AccesoTablasRecuerdosSupabase(),
    medios: ref.watch(proveedorRepositorioMedios),
    uidActual: () => autenticacion.usuarioActual?.uid,
    reloj: ref.watch(proveedorReloj),
  );
});

/// Entrega segura de medios (se sobrescribe en pruebas). Se recrea al
/// cambiar de usuario para no reutilizar URLs de otra sesión.
final proveedorRepositorioUrlsMedio = Provider<RepositorioUrlsMedio>((ref) {
  ref.watch(
    proveedorEstadoAutenticacion.select((estado) => estado.value?.uid),
  );
  return RepositorioUrlsMedioAgrupado(solicitar: solicitarUrlsMedioSupabase);
});

/// Archivos de medios en el dispositivo (se sobrescribe en pruebas). Al
/// cerrar sesión o cambiar de cuenta se vacían.
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

/// Caché del dispositivo + enlaces firmados vigentes.
final proveedorCargadorMedios = Provider<CargadorMedios>(
  (ref) => CargadorMedios(
    urls: ref.watch(proveedorRepositorioUrlsMedio),
    archivos: ref.watch(proveedorArchivosMedio),
  ),
);

/// Archivo local de la variante pedida (`null` si no hay o falló).
final proveedorArchivoMedio =
    FutureProvider.autoDispose.family<File?, SolicitudMedio>(
  (ref, solicitud) => ref.watch(proveedorCargadorMedios).archivo(solicitud),
);

/// Solicitud de la [variante] del medio de [recuerdo] o `null` si no tiene
/// (notas, recuerdos sin subir o audio sin miniatura).
SolicitudMedio? solicitudMedioDe(Recuerdo recuerdo, VarianteMedio variante) {
  final publicId = recuerdo.publicId;
  if (publicId == null) return null;
  if (variante == VarianteMedio.miniatura && !recuerdo.esVisual) return null;
  return (idRecuerdo: recuerdo.id, publicId: publicId, variante: variante);
}

/// Recuerdos propios que pasan el filtro.
final proveedorRecuerdos = FutureProvider.autoDispose
    .family<List<Recuerdo>, FiltroRecuerdos>(
  (ref, filtro) => ref.watch(proveedorRepositorioRecuerdos).listar(filtro),
);

/// Un recuerdo por id.
final proveedorRecuerdo = FutureProvider.autoDispose.family<Recuerdo?, String>(
  (ref, id) => ref.watch(proveedorRepositorioRecuerdos).obtener(id),
);

/// Espacio usado de la cuota de 200 MB.
final proveedorUsoMedios = FutureProvider.autoDispose<UsoMedios>(
  (ref) => ref.watch(proveedorRepositorioRecuerdos).leerUsoMedios(),
);

/// Filtro elegido en la pantalla Recuerdos.
class ControladorFiltroRecuerdos extends Notifier<FiltroRecuerdos> {
  @override
  FiltroRecuerdos build() => FiltroRecuerdos.todos;

  void cambiar(FiltroRecuerdos filtro) => state = filtro;
}

final proveedorFiltroRecuerdos =
    NotifierProvider<ControladorFiltroRecuerdos, FiltroRecuerdos>(
  ControladorFiltroRecuerdos.new,
);
