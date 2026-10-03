import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../autenticacion/aplicacion/proveedores_autenticacion.dart';
import '../../capsulas/aplicacion/proveedores_capsulas.dart';
import '../../elementos/aplicacion/proveedores_elementos.dart';
import '../datos/acceso_tablas_recuerdos.dart';
import '../datos/repositorio_recuerdos_supabase.dart';
import '../datos/repositorio_urls_medio_agrupado.dart';
import '../dominio/filtro_recuerdos.dart';
import '../dominio/recuerdo.dart';
import '../dominio/repositorio_recuerdos.dart';
import '../dominio/repositorio_urls_medio.dart';
import '../dominio/url_medio.dart';
import '../dominio/uso_medios.dart';

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

/// URLs firmadas del medio de un recuerdo (`null` si no hay).
final proveedorUrlMedio = FutureProvider.autoDispose.family<UrlMedio?, String>(
  (ref, id) => ref.watch(proveedorRepositorioUrlsMedio).obtener(id),
);

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
