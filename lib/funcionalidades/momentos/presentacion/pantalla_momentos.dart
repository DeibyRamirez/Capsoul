import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/componentes/encabezado_seccion_capsoul.dart';
import '../../../nucleo/componentes/esqueleto_capsoul.dart';
import '../../../nucleo/componentes/estado_error_capsoul.dart';
import '../../../nucleo/componentes/pantalla_capsoul.dart';
import '../../../nucleo/errores/fallo_app.dart';
import '../aplicacion/proveedor_filtro_momentos.dart';
import '../aplicacion/proveedores_momentos.dart';
import '../dominio/momento.dart';
import 'componentes/barra_busqueda_momentos.dart';
import 'componentes/chips_filtro_momentos.dart';
import 'componentes/rejilla_momentos.dart';

/// Pestaña "Momentos": búsqueda, filtros y rejilla de 2 columnas.
class PantallaMomentos extends ConsumerWidget {
  const PantallaMomentos({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final momentosAsincrono = ref.watch(proveedorMomentos);
    final filtro = ref.watch(proveedorFiltroMomentos);

    final momentosFiltrados = momentosAsincrono.maybeWhen(
      data: (lista) => filtro.aplicar(lista),
      orElse: () => const <Momento>[],
    );

    return PantallaCapsoul(
      cuerpo: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(proveedorMomentos);
          await ref.read(proveedorMomentos.future);
        },
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: EncabezadoSeccionCapsoul(
                titulo: 'Momentos',
                subtitulo: 'Tus recuerdos, tu historia.',
                icono: Icons.local_florist_outlined,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: BarraBusquedaMomentos(
                  consulta: filtro.consulta,
                  alCambiar: ref
                      .read(proveedorFiltroMomentos.notifier)
                      .actualizarConsulta,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 10)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ChipsFiltroMomentos(
                  tipoSeleccionado: filtro.tipoPortada,
                  alCambiar: ref
                      .read(proveedorFiltroMomentos.notifier)
                      .actualizarTipo,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            momentosAsincrono.when(
              loading: () => const SliverEsqueletoRejillaCapsoul(),
              error: (error, _) => SliverEstadoErrorCapsoul(
                mensaje: mensajeParaUsuario(error),
                alReintentar: () => ref.invalidate(proveedorMomentos),
              ),
              data: (_) => RejillaMomentos(
                momentos: momentosFiltrados,
                mensajeVacio: filtro.esVacio
                    ? 'Aún no tienes momentos. Junta varios recuerdos '
                        'bajo un mismo nombre: un viaje, un cumpleaños, un año.'
                    : 'Ningún momento coincide con tu búsqueda.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
