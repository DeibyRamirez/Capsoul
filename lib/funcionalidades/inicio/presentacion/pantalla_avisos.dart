import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../nucleo/componentes/app_bar_capsoul.dart';
import '../../../nucleo/componentes/pantalla_capsoul.dart';
import '../../../nucleo/componentes/tarjeta_capsoul.dart';
import '../../../nucleo/componentes/avisos_emergentes.dart';
import '../../../nucleo/enrutador/rutas_app.dart';
import '../../../nucleo/errores/fallo_app.dart';
import '../../../nucleo/formato/fechas.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../../autenticacion/aplicacion/proveedores_autenticacion.dart';
import '../../capsulas/aplicacion/proveedores_capsulas.dart';
import '../../capsulas/dominio/avisos_capsulas.dart';
import '../../capsulas/dominio/capsula_recibida.dart';

/// Lista de cápsulas compartidas que ya se liberaron, de la más nueva a la más vieja.
class PantallaAvisos extends ConsumerWidget {
  const PantallaAvisos({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(proveedorEstadoAutenticacion).value?.uid;
    final recibidas = ref.watch(proveedorCapsulasRecibidas);

    return PantallaCapsoul(
      appBar: AppBarCapsoul(
        titulo: const Text('Avisos'),
        alAtras: () => context.pop(),
      ),
      cuerpo: recibidas.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _EstadoAvisos(
          mensaje: mensajeParaUsuario(error),
          alReintentar: () => ref.invalidate(proveedorCapsulasRecibidas),
        ),
        data: (lista) {
          final avisos = avisosCapsulasCompartidas(lista, uid);
          if (avisos.isEmpty) {
            return const _EstadoAvisos(
              mensaje: 'Cuando alguien te envíe una cápsula y se abra, aparecerá aquí.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(proveedorCapsulasRecibidas);
              await ref.read(proveedorCapsulasRecibidas.future);
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: avisos.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, indice) =>
                  _TarjetaAviso(aviso: avisos[indice]),
            ),
          );
        },
      ),
    );
  }
}

class _TarjetaAviso extends ConsumerWidget {
  const _TarjetaAviso({required this.aviso});

  final CapsulaRecibida aviso;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estilos = Theme.of(context).textTheme;
    final cuando = aviso.liberadaEn ?? aviso.fechaApertura;
    final sinLeer = aviso.leidaEn == null;

    return TarjetaCapsoul(
      icono: Icons.mail_outline,
      titulo: aviso.tituloVisible,
      alTocar: () => _abrir(context, ref),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'De ${aviso.autorNombre}',
                  style: estilos.bodyMedium?.copyWith(
                    color: ColoresApp.textoPrincipal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatearFechaHora(cuando),
                  style: estilos.bodySmall?.copyWith(
                    color: ColoresApp.textoSecundario,
                  ),
                ),
              ],
            ),
          ),
          if (sinLeer)
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: ColoresApp.acento,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _abrir(BuildContext context, WidgetRef ref) async {
    if (aviso.leidaEn == null) {
      try {
        await ref.read(proveedorRepositorioCapsulas).marcarAvisoLeido(aviso.id);
        ref.invalidate(proveedorCapsulasRecibidas);
      } catch (error) {
        if (context.mounted) mostrarAvisoError(context, error);
        return;
      }
    }
    if (!context.mounted) return;
    await context.push(RutasApp.detalleCapsulaDe(aviso.id));
  }
}

class _EstadoAvisos extends StatelessWidget {
  const _EstadoAvisos({required this.mensaje, this.alReintentar});

  final String mensaje;
  final VoidCallback? alReintentar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(color: ColoresApp.textoSecundario),
            ),
            if (alReintentar != null) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: alReintentar,
                child: const Text('Reintentar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
