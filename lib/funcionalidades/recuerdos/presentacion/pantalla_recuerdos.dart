import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../nucleo/componentes/encabezado_seccion_capsoul.dart';
import '../../../nucleo/componentes/pantalla_capsoul.dart';
import '../../../nucleo/errores/fallo_app.dart';
import '../../capsulas/aplicacion/proveedores_capsulas.dart';
import '../aplicacion/proveedores_recuerdos.dart';
import 'componentes/barra_filtros_recuerdos.dart';
import 'componentes/barra_uso_medios.dart';
import 'componentes/rejilla_recuerdos.dart';
import 'navegacion_visor_recuerdo.dart';

/// Banco de recuerdos: todos los elementos guardados por el usuario, con
/// filtros por tipo y fecha y el espacio usado.
class PantallaRecuerdos extends ConsumerWidget {
  const PantallaRecuerdos({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtro = ref.watch(proveedorFiltroRecuerdos);
    final recuerdos = ref.watch(proveedorRecuerdos(filtro));
    final uso = ref.watch(proveedorUsoMedios);
    final hoy = ref.watch(proveedorReloj)();

    return PantallaCapsoul(
      cuerpo: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(proveedorRecuerdos(filtro));
          ref.invalidate(proveedorUsoMedios);
          await ref.read(proveedorRecuerdos(filtro).future);
        },
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: EncabezadoSeccionCapsoul(
                titulo: 'Recuerdos',
                subtitulo: 'Tu banco de recuerdos.',
                icono: Icons.collections_outlined,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: uso.when(
                  data: (datos) => BarraUsoMedios(uso: datos),
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: BarraFiltrosRecuerdos(
                filtro: filtro,
                hoy: hoy,
                alCambiar: ref.read(proveedorFiltroRecuerdos.notifier).cambiar,
              ),
            ),
            ...recuerdos.when(
              loading: () => const [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
              error: (error, _) => [
                SinRecuerdos(
                  mensaje: mensajeParaUsuario(error),
                  accion: OutlinedButton(
                    onPressed: () => ref.invalidate(proveedorRecuerdos(filtro)),
                    child: const Text('Reintentar'),
                  ),
                ),
              ],
              data: (lista) => [
                if (lista.isEmpty)
                  SinRecuerdos(
                    mensaje: filtro.esVacio
                        ? 'Aún no tienes recuerdos. Guarda una foto, un video, '
                            'una nota de voz o una nota.'
                        : 'Ningún recuerdo coincide con el filtro.',
                  )
                else
                  RejillaRecuerdos(
                    recuerdos: lista,
                    alTocar: (recuerdo) => mostrarVisorPublicacionRecuerdo(
                      context,
                      ref,
                      recuerdo,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
