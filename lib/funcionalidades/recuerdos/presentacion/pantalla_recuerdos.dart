import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../nucleo/componentes/pantalla_capsoul.dart';
import '../../../nucleo/enrutador/rutas_app.dart';
import '../../../nucleo/errores/fallo_app.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../../capsulas/aplicacion/proveedores_capsulas.dart';
import '../aplicacion/proveedores_recuerdos.dart';
import 'componentes/barra_filtros_recuerdos.dart';
import 'componentes/barra_uso_medios.dart';
import 'componentes/hoja_nuevo_recuerdo.dart';
import 'componentes/rejilla_recuerdos.dart';

/// Banco de recuerdos: todos los elementos guardados por el usuario, con
/// filtros por tipo y fecha y el espacio usado.
class PantallaRecuerdos extends ConsumerWidget {
  const PantallaRecuerdos({super.key});

  Future<void> _nuevo(BuildContext context) async {
    final tipo = await elegirTipoRecuerdo(context);
    if (tipo == null || !context.mounted) return;
    await capturarRecuerdo(context, tipo);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtro = ref.watch(proveedorFiltroRecuerdos);
    final recuerdos = ref.watch(proveedorRecuerdos(filtro));
    final uso = ref.watch(proveedorUsoMedios);
    final hoy = ref.watch(proveedorReloj)();

    return PantallaCapsoul(
      appBar: AppBar(title: const Text('Recuerdos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _nuevo(context),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo recuerdo'),
      ),
      cuerpo: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(proveedorRecuerdos(filtro));
          ref.invalidate(proveedorUsoMedios);
          await ref.read(proveedorRecuerdos(filtro).future);
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tu banco de recuerdos',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: ColoresApp.primario,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    if (uso.value case final datos?)
                      BarraUsoMedios(uso: datos),
                  ],
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
                    alTocar: (recuerdo) =>
                        context.push(RutasApp.detalleRecuerdoDe(recuerdo.id)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
